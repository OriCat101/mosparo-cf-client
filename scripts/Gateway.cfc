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

  /**
   * @hint initialize component
   * @return this
   */
  public component function init(){
    // variables.m = application.serviceFactory.getBean("m");
    variables.htmlId      = 'mosparo-box';
    variables.host        = 'http://127.0.0.1:8080';
    variables.apiEndpoint = '/api/v1/verification/verify';
    variables.uuid        = 'd1653c66-dd23-4f63-8e96-2d1bd3836e04';
    variables.publicKey   = 'AUfQvl1b4Rm_FQLijdrFVb-Rn-Aqu7gQbY_8W4jL3SM';
    variables.privateKey  = 'FoCOk54YFXkbzXmRog7V7zGuwboHvyp1RhssfdMhh9A';
  
    return this;
  }

  /**
   * initialize process
   */
  public struct function initializeProcess(
    required struct data
  ){
    savePureForm(data=arguments.data);
    prepareFormData();
    extractTokens();
    signFormFields();
    generateSignatures();

    // send data to mosparo
    local.requestData = [
      'submitToken'         : variables.submitToken,
      'validationSignature' : variables.formSignatures.validationSignature,
      'formSignature'       : variables.formSignatures.formSignature,
      'formData'            : variables.signedForm,
    ];
    local.requestSignature = generateSignature(string='#getApiEndpoint()##serializeJSON(variables.signedForm)#');

    writeDump(this);
    http charset='UTF-8'
    method='POST'
    result='local.result'
    url='#getHost()##getApiEndpoint()#'
    {
      // httpparam type='header' name='Accept'         value='application/json';
      httpparam type='header' name='Authorization'  value='#getPublicKey()#:#local.requestSignature#';
      httpparam name="submitToken" type="formField" value="#variables.submitToken#";
      httpparam name="validationSignature" type="formField" value="#variables.formSignatures.validationSignature#";
      httpparam name="formSignature" type="formField" value="#variables.formSignatures.formSignature#";
      httpparam name="formData" type="formField" value="#serializeJSON(variables.signedForm)#";
    }

    writeDump(local.result);
    abort;

    return local.allData;
  }

  /**
   * sign form fields
   */
  private void function signFormFields(){
    variables.signedForm = {};
    for (local.key in variables.preparedForm){
      variables.signedForm[lCase(local.key)] = generateSignature(string=variables.preparedForm[local.key]);
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
    return replace(arguments.string, '#chr(13)##chr(10)#', ' ');
  }
}