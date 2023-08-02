<cfscript>
  local.G = new Gateway();

  cfhtmlhead(text='<link href="#local.G.getHost()#/resources/#local.G.getUuid()#.css" rel="stylesheet" />');
  cfhtmlhead(text='<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>');


  if (structKeyExists(form, "firstname")) {
    local.preparedData = local.G.initializeProcess(data=form);
    writeDump(local.preparedData);
  }
</cfscript>
<!--- ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== --->
<cfoutput>

<h1>My Form</h1>

<form method="POST">

  <label for="firstname">Vorname</label>
  <input type="text" name="firstname" id="firstname" placeholder="Name" value="Nicolas">

  <br><br>
  <div id="#local.G.getHtmlId()#"></div>
  <br><br>

  <input type="submit" value="Senden">

</form>

<!--- ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== --->
<script src="#local.G.getHost()#/build/mosparo-frontend.js" defer></script>
<script>
  var mosparo;
  window.onload = function(){
    mosparo = new mosparo(
      '#local.G.getHtmlId()#',
      '#local.G.getHost()#',
      '#local.G.getUuid()#',
      '#local.G.getPublicKey()#',
      {
        customMessages: {
          de_CH: {
            label: "Ich akzeptiere, dass die Formulareingaben auf Spam geprüft und 14 Tage lang verschlüsselt gespeichert werden.",
            accessibilityCheckingData: "Wir überprüfen Ihre Daten. Bitte warten.",
            accessibilityDataValid: "Ihre Daten sind gültig. Sie können das Formular absenden.",
            errorSpamDetected: "Spam erkannt. Bitte versuchen Sie es erneut.",
            errorLockedOut: "Sie sind blockiert. Bitte versuchen Sie es nach %datetime% erneut.",
            errorDelay: "Ihre Anfrage wurde verzögert. Bitte warten Sie für %seconds% Sekunden.",
            hpLeaveEmpty: "Bitte lassen Sie dieses Feld leer."
          }
        }
      }
    );
  };
  
  $('form').submit(function(event) {
    $('input[name="_mosparo_submitToken"]').attr('name', 'mosparo_submitToken');
		$('input[name="_mosparo_validationToken"]').attr('name', 'mosparo_validationToken');
  });
</script>

</cfoutput>