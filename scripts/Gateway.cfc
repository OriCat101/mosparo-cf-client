component 
  accessors="true" 
  output="false"
{
  // property type="component" name="m";
  property type="String" name="htmlId";
  property type="String" name="host";
  property type="String" name="apiEndpoint";
  property type="String" name="uuid";
  property type="String" name="publicKey";
  property type="String" name="privateKey";

  // available during process
  property type="struct" name="form";
  property type="struct" name="preparedForm";
  property type="String" name="submitToken";
  property type="String" name="validationToken";
  property type="struct" name="signedForm";
  property type="struct" name="formSignatures";
  property type="struct" name="objectParams";

  /**
   * @hint initialize component
   * @return this
   */
  public component function init(
    required struct objectParams
  ){
    variables.htmlId      = 'mosparo-box';
    variables.apiEndpoint = '/api/v1/verification/verify';
    variables.host        = objectParams.mosparoHost;
    variables.uuid        = objectParams.mosparoUUID;
    variables.publicKey   = objectParams.mosparoPublicKey;
    variables.privateKey  = objectParams.mosparoPrivateKey;
  
    return this;
  }

  /**
   * initialize process
   */
  public boolean function initializeProcess(
    required struct data
  ){
    savePureForm(data=arguments.data);
    prepareFormData();
    extractTokens();
    signFormFields();
    generateSignatures();
    
    local.requestData = [
      'submitToken'         : variables.submitToken,
      'validationSignature' : variables.formSignatures.validationSignature,
      'formSignature'       : variables.formSignatures.formSignature,
      'formData'            : variables.signedForm,
    ];

    getAuthorizationHeader(local.requestData);

    // send data to mosparo
    http charset='UTF-8'
    method='POST'
    result='local.result'
    url='#getHost()##getApiEndpoint()#'
    {
      httpparam type='header' name='Authorization' value='#variables.authHeader#';
      httpparam type='header' name='Content-Type' value='application/json';
      httpparam type="body" value="#serializeJSON(local.requestData)#";
    }

    local.isValid = false;
    if (structKeyExists(deserializeJSON(local.result.filecontent), "valid")) {
      local.isValid = deserializeJSON(local.result.filecontent)["valid"];
    }

    return local.isValid;
  }

  /**
   * sign form fields
   */
  private void function signFormFields(){
    variables.signedForm = {};
    for (local.key in variables.preparedForm){
      variables.signedForm[lCase(local.key)] = lCase(hash(variables.preparedForm[local.key], "SHA-256"));
    }
  }

  /**
   * generate signatures
   */
  private void function generateSignatures(){
    local.formJson = serializeJSON(var=variables.signedForm);
    local.formJson = replaceNoCase(local.formJson, '[]', '{}'); // replace empty array with empty object

    variables.formSignatures['formSignature']         = generateSignature(string=local.formJson);
    variables.formSignatures['validationSignature']   = generateSignature(string=variables.validationToken);
    variables.formSignatures['verificationSignature'] = generateSignature(string='#variables.formSignatures.validationSignature##variables.formSignatures.formSignature#');
  }

  /**
   * extract mosparo tokens
   */
  private void function extractTokens(){
    variables.submitToken     = variables.form.mosparo_submitToken;
    variables.validationToken = variables.form.mosparo_validationToken;
  }

  /**
   * save pure form
   */
  private void function savePureForm(required Struct data){
    variables.form = arguments.data;
  }

  /**
   * filter and alter data for mosparo (mosparo specific)
   * https://documentation.mosparo.io/docs/integration/custom#preparing-form-data
   */
  private void function prepareFormData(){
    local.filterKeys = ['mosparo_submitToken', 'mosparo_validationToken', 'fieldnames'];
    for (local.key in variables.form){
      if (arrayFind(local.filterKeys, local.key)) continue;
      variables.preparedForm[local.key] = replaceCRLF(string=variables.form[local.key]);
    }
  }

  /**
   * generate signature
   */
  private String function generateSignature(required String string){
    return lCase(hmac(
      message=arguments.string,
      key=getPrivateKey(),
      algorithm='HmacSHA256'
    ));
  }

  /**
   * replace crlf
   */
  private String function replaceCRLF(required String string){
    return rereplace(arguments.string, "\r\n", "#chr(10)#", "all");
  }

  /**
   * Generates the authorization header for the API call.
   *
   * @param formData The data struct to be used in generating the header.
   */
  private void function getAuthorizationHeader(
    required struct formData,
    string publicKey = variables.publicKey,
    string privateKey = variables.privateKey
  ) {
    local.hash = lCase(hmac(getApiEndpoint() & serializeJSON(arguments.formData), getPrivateKey(), 'HmacSHA256'));
    local.autHeader = toBase64(arguments.publicKey & ":" & local.hash);

    variables.authHeader = local.autHeader;
  }
}