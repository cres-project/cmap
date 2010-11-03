

var LemurLogToolbarConfiguration=window.arguments[0];

var PersonalBLItemsRegex=new Array();
var AddressBLItemsRegex=new Array();
var ProperNameBLItemsRegex=new Array();
var KeywordBLItemsRegex=new Array();

var KnownSearchEnginePrefixes=new Array();

/**
 * retrieves the value as a boolean from a checkbox element
 * @param checkboxId the name of the checkbox component
 * @return true or value (value)
 */
function getCheckboxItemValue(checkboxId) {
  var thisBox=document.getElementById(checkboxId);
  if (thisBox) {
    return thisBox.checked;
  }
  return false;
}

function setCheckboxItemValue(checkboxId, newvalue) {
  var thisBox=document.getElementById(checkboxId);
  if (thisBox) {
    thisBox.checked=newvalue;
  }
}

/**
 * retrieves a listbox element's values and places them
 * in a string delimited by \n
 * @param lstItem the list element
 * @return encoded string
 */
function getListItemAsString(lstItemId) {
  var lstItem=document.getElementById(lstItemId);
  if (!lstItem) { return ""; }
  
  var retString="";
  var hasOne=false;
  var numItems=lstItem.getRowCount();
  for (var i=0; i < numItems; i++) {
    var thisItemValue=lstItem.getItemAtIndex(i).value;
    if (thisItemValue.length > 0) {
      if (hasOne) { retString +="\n"; }
      retString += thisItemValue;
      hasOne=true;
    }
  }
  return retString;
}

function getArrayItemAsString(thisArray) {
  var retString="";
  var hasOne=false;
  for (var i=0; i < thisArray.length; i++) {
    if (hasOne) { retString +="\n"; }
    retString += thisArray[i];
    hasOne=true;
  }
  return retString;
}

/**
 * populates a listbox element's values 
 * 
 * @param lstItemId the ID of list element
 * @param inString the input string (\n delimited)
 */
function populateListboxFromString(lstItemId, inString) {
  var lstItem=document.getElementById(lstItemId);
  if (!lstItem) { return; }
  
  // clear the listbox
  while (lstItem.getRowCount() != 0) {
    lstItem.removeItemAt(0);
  
  }
  var items=inString.split("\n");
  for (var i=0; i < items.length; i++) {
    if (items[i].length > 0) {
      lstItem.appendItem(items[i], items[i]);
    }
  }
}

function populateArrayFromString(inString) {
  var thisArray=new Array();
  var items=inString.split("\n");
  for (var i=0; i < items.length; i++) {
    if (items[i].length > 0) {
      thisArray[i]=items[i];
    }
  }
  return thisArray;
}

function setOptionsSettings() {
  LemurLogToolbarConfiguration.loadLocalUserConfiguration();
  LemurLogToolbarConfiguration.getDefaultServerConfiguration();

  // if (LemurLogToolbarConfiguration._serverBaseURL.length==0) {
  //  LemurLogToolbarConfiguration._serverBaseURL=window.prompt("No server address is defined\nPlease enter one\n(or leave blank for none):");
  // }
  
  // load current configuration here...
  if (LemurLogToolbarConfiguration._allowRandomSessionId==false) {
    var thisCheckbox=document.getElementById('chkAnonSession');
    thisCheckbox.value=false;
    thisCheckbox.disabled=true;
  }
  
  if (LemurLogToolbarConfiguration._allowBlacklistPersonal==false) {
    var thisCheckbox=document.getElementById('chkPersonalData');
    thisCheckbox.value=false;
    thisCheckbox.disabled=true;
    var thisListbox=document.getElementById('tabBlacklistPersonal');
    thisListbox.disabled=true; 
  }

  if (LemurLogToolbarConfiguration._allowBlacklistAddress==false) {
    var thisCheckbox=document.getElementById('chkAddressData');
    thisCheckbox.value=false;
    thisCheckbox.disabled=true;
    var thisListbox=document.getElementById('tabBlacklistAddress');
    thisListbox.disabled=true; 
  }
  
  if (LemurLogToolbarConfiguration._allowBlacklistProperName==false) {
    var thisCheckbox=document.getElementById('chkProperNameData');
    thisCheckbox.value=false;
    thisCheckbox.disabled=true;
    var thisListbox=document.getElementById('tabBlacklistNames');
    thisListbox.disabled=true; 
  }
  
  if (LemurLogToolbarConfiguration._allowBlacklistKeywords==false) {
    var thisCheckbox=document.getElementById('chkKeywordData');
    thisCheckbox.value=false;
    thisCheckbox.disabled=true;
    var thisListbox=document.getElementById('tabBlacklistKeywords');
    thisListbox.disabled=true; 
  }
  
  populateListboxFromString('lstBlacklistPersonalData', LemurLogToolbarConfiguration._blacklistPersonalItems);
  populateListboxFromString('lstBlacklistAddressData', LemurLogToolbarConfiguration._blacklistAddressItems);
  populateListboxFromString('lstBlacklistNameData', LemurLogToolbarConfiguration._blacklistPropernameItems);
  populateListboxFromString('lstBlacklistKeywordData', LemurLogToolbarConfiguration._blacklistKeywordItems);
  
  PersonalBLItemsRegex=populateArrayFromString(LemurLogToolbarConfiguration._blacklistPersonalRegex);
  AddressBLItemsRegex=populateArrayFromString(LemurLogToolbarConfiguration._blacklistAddressRegex);
  ProperNameBLItemsRegex=populateArrayFromString(LemurLogToolbarConfiguration._blacklistPropernameRegex);
  KeywordBLItemsRegex=populateArrayFromString(LemurLogToolbarConfiguration._blacklistKeywordRegex);
  
  setCheckboxItemValue('chkAnonSession', LemurLogToolbarConfiguration._useRandomSessionId);
  setCheckboxItemValue('chkUseDesktopSearch', LemurLogToolbarConfiguration._useDesktopSearch);
  setCheckboxItemValue('chkPersonalData', LemurLogToolbarConfiguration._useBlacklistPersonal);
  setCheckboxItemValue('chkAddressData', LemurLogToolbarConfiguration._useBlacklistAddress);
  setCheckboxItemValue('chkProperNameData', LemurLogToolbarConfiguration._useBlacklistProperName);
  setCheckboxItemValue('chkKeywordData', LemurLogToolbarConfiguration._useBlacklistKeywords);
  
  populateListboxFromString('lstSearchEngines', LemurLogToolbarConfiguration._knownSearchEngines);
  
  chkPersonalDataOnChange();
  chkAddressDataOnChange();
  chkProperNameDataOnChange();
  chkKeywordDataOnChange();
     
  var txtServer=document.getElementById('txtServer');
  txtServer.value=LemurLogToolbarConfiguration._serverBaseURL;
  
  setAutoUploadVisualSettings();
}

function setAutoUploadVisualSettings() {
  var autoUploadRB=document.getElementById('btnAllowAutoUploads');
  var manualUploadOnlyRB=document.getElementById('btnManualUploadsOnly');
  var autoUploadAskRB=document.getElementById('btnAutoUploadsWithAsk');
  var grpAutoUploadBox=document.getElementById('rdoGroupAutoUploads');
  var lblAutoUploads=document.getElementById('lblAutoUploads');
  
  grpAutoUploadBox.selectedIndex=1;
  if (LemurLogToolbarConfiguration._serverAllowAutoUploads==false) {
    // manual upload only
    manualUploadOnlyRB.disabled=false;
    autoUploadRB.disabled=true;
    autoUploadAskRB.disabled=true;
    lblAutoUploads.label="Automatic Uploads: (server does not allow)";
  } else {
    manualUploadOnlyRB.disabled=false;
    autoUploadRB.disabled=false;
    autoUploadAskRB.disabled=false;
    lblAutoUploads.label="Automatic Uploads: (manual upload selected)";
    if (LemurLogToolbarConfiguration._useAutomaticUploads==true) {
      lblAutoUploads.label="Automatic Uploads: next upload at:\n" + LemurLogToolbarConfiguration.getNextAutoUploadTimeString();
      grpAutoUploadBox.selectedIndex=0;
      if (LemurLogToolbarConfiguration._askWhenUsingAutoUploads==true) {
        grpAutoUploadBox.selectedIndex=2;
      }
    }
  }
  
  // var thisDialog=document.getElementById('dlgToolbarSettings');
  try {
    window.sizeToContent();
  } catch (excp) {
    // do nothing
  }
}

function saveSettings() {
  // LemurLogToolbarConfiguration.loadLocalUserConfiguration();
  
  var txtServer=document.getElementById('txtServer');
  
  LemurLogToolbarConfiguration._serverBaseURL=txtServer.value;
  LemurLogToolbarConfiguration._useRandomSessionId=getCheckboxItemValue('chkAnonSession');
  LemurLogToolbarConfiguration._useDesktopSearch=getCheckboxItemValue('chkUseDesktopSearch');
  
  var autoUploadRB=document.getElementById('btnAllowAutoUploads');
  var manualUploadOnlyRB=document.getElementById('btnManualUploadsOnly');
  var autoUploadAskRB=document.getElementById('btnAutoUploadsWithAsk');
  
  if (autoUploadRB.selected==true) {
    // auto upload without ask
    LemurLogToolbarConfiguration._useAutomaticUploads=true;
    LemurLogToolbarConfiguration._askWhenUsingAutoUploads=false;
  } else if (autoUploadAskRB.selected==true) {
    // auto upload ask
    LemurLogToolbarConfiguration._useAutomaticUploads=true;
    LemurLogToolbarConfiguration._askWhenUsingAutoUploads=true;
  } else {
    // manual upload
    LemurLogToolbarConfiguration._useAutomaticUploads=false;
    LemurLogToolbarConfiguration._askWhenUsingAutoUploads=false;
  }
  
  LemurLogToolbarConfiguration._blacklistPersonalItems=getListItemAsString('lstBlacklistPersonalData');
  LemurLogToolbarConfiguration._blacklistAddressItems=getListItemAsString('lstBlacklistAddressData');
  LemurLogToolbarConfiguration._blacklistPropernameItems=getListItemAsString('lstBlacklistNameData');
  LemurLogToolbarConfiguration._blacklistKeywordItems=getListItemAsString('lstBlacklistKeywordData');
  
  LemurLogToolbarConfiguration._blacklistPersonalRegex=getArrayItemAsString(PersonalBLItemsRegex);
  LemurLogToolbarConfiguration._blacklistAddressRegex=getArrayItemAsString(AddressBLItemsRegex);
  LemurLogToolbarConfiguration._blacklistPropernameRegex=getArrayItemAsString(ProperNameBLItemsRegex);
  LemurLogToolbarConfiguration._blacklistKeywordRegex=getArrayItemAsString(KeywordBLItemsRegex);

  LemurLogToolbarConfiguration._useBlacklistPersonal=getCheckboxItemValue('chkPersonalData');
  LemurLogToolbarConfiguration._useBlacklistAddress=getCheckboxItemValue('chkAddressData');
  LemurLogToolbarConfiguration._useBlacklistProperName=getCheckboxItemValue('chkProperNameData');
  LemurLogToolbarConfiguration._useBlacklistKeywords=getCheckboxItemValue('chkKeywordData');
  
  LemurLogToolbarConfiguration._knownSearchEngines=getListItemAsString('lstSearchEngines');
  
  LemurLogToolbarConfiguration.saveLocalUserConfiguration();

  setAutoUploadVisualSettings();

  return true;
}

function txtServerOnChange() {
  var txtServer=document.getElementById('txtServer');
  
  LemurLogToolbarConfiguration.loadLocalUserConfiguration();
  if (txtServer.value!=LemurLogToolbarConfiguration._serverBaseURL) {
    var doReloadVal=window.confirm("The server address has changed.\nClick \"OK\" to retrieve the server configuration.");
    if (doReloadVal) {
      LemurLogToolbarConfiguration._serverBaseURL=txtServer.value;
      LemurLogToolbarConfiguration.saveLocalUserConfiguration();
      LemurLogToolbarConfiguration.getDefaultServerConfiguration(true);
      setOptionsSettings();
    }
  }
}

function chkPersonalDataOnChange() {
  var thisCheckbox=document.getElementById('chkPersonalData');
  var thisListbox=document.getElementById('lstBlacklistPersonalData');
  if (thisCheckbox.checked) {
    thisListbox.disabled=false;
  } else {
    thisListbox.disabled=true;
  }
  drpBlacklists_OnSelect();
}

function chkAddressDataOnChange() {
  var thisCheckbox=document.getElementById('chkAddressData');
  var thisListbox=document.getElementById('lstBlacklistAddressData');
  if (thisCheckbox.checked) {
    thisListbox.disabled=false;
  } else {
    thisListbox.disabled=true;
  }
  drpBlacklists_OnSelect();
}

function chkProperNameDataOnChange() {
  var thisCheckbox=document.getElementById('chkProperNameData');
  var thisListbox=document.getElementById('lstBlacklistNameData');
  if (thisCheckbox.checked) {
    thisListbox.disabled=false;
  } else {
    thisListbox.disabled=true;
  }
  drpBlacklists_OnSelect();
}

function chkKeywordDataOnChange() {
  var thisCheckbox=document.getElementById('chkKeywordData');
  var thisListbox=document.getElementById('lstBlacklistKeywordData');
  if (thisCheckbox.checked) {
    thisListbox.disabled=false;
  } else {
    thisListbox.disabled=true;
  }
  drpBlacklists_OnSelect();
}

function setWhichBlacklistItems(thisListBox) {
  var groupLabel=document.getElementById('lblBlacklistGroup');
  document.getElementById('btnRemoveListItem').disabled=true;
  if (thisListBox.disabled) {
    document.getElementById('txtNewListItem').disabled=true;
    document.getElementById('btnAddListItem').disabled=true;
    groupLabel.value += ' (disabled)';
  } else {
    document.getElementById('txtNewListItem').disabled=false;
    document.getElementById('btnAddListItem').disabled=false;
  }
}

// when user selects the dropdown menu for blacklists
function drpBlacklists_OnSelect() {
  var drpBlacklists=document.getElementById('drpBlacklists');
  var groupLabel=document.getElementById('lblBlacklistGroup');
  var groupTab=document.getElementById('tbBlacklists');
  var whichPanel;
  switch (drpBlacklists.selectedIndex) {
    case 0:
      groupLabel.setAttribute('value', 'Personal Data:');
      whichPanel=document.getElementById('tabBlacklistPersonal');
      break;
    case 1:
      groupLabel.setAttribute('value', 'Addresses:');
      whichPanel=document.getElementById('tabBlacklistAddress');
      break;
    case 2:
      groupLabel.setAttribute('value', 'Proper Names:');
      whichPanel=document.getElementById('tabBlacklistNames');
      break;
    default:
      groupLabel.setAttribute('value', 'Keywords:');
      whichPanel=document.getElementById('tabBlacklistKeywords');
  }
  groupTab.selectedPanel=whichPanel;
  setWhichBlacklistItems(getWhichBlacklistControl());
}

function getWhichBlacklistControl() {
  var drpBlacklists=document.getElementById('drpBlacklists');
  switch (drpBlacklists.selectedIndex) {
    case 0: return document.getElementById('lstBlacklistPersonalData');
    case 1: return document.getElementById('lstBlacklistAddressData');
    case 2: return document.getElementById('lstBlacklistNameData');
    default: return document.getElementById('lstBlacklistKeywordData');
  }
}

function getWhichRegexArray() {
  var drpBlacklists=document.getElementById('drpBlacklists');
  switch (drpBlacklists.selectedIndex) {
    case 0: return PersonalBLItemsRegex;
    case 1: return AddressBLItemsRegex;
    case 2: return ProperNameBLItemsRegex;
    default: return KeywordBLItemsRegex;
  }
}

function btnRemoveListItemOnClick() {
  var thisListBox=getWhichBlacklistControl();
  var thisArray=getWhichRegexArray();
  if (thisListBox.selectedIndex > -1) {
    thisArray.splice(thisListBox.selectedIndex, 1);
    thisListBox.removeItemAt(thisListBox.selectedIndex);
  }
}

function btnAddListItemOnClick() {
  var thisListBox=getWhichBlacklistControl();
  var thisTextBox=document.getElementById('txtNewListItem');
  var thisArray=getWhichRegexArray();
  var thisValue=thisTextBox.value;
  if (thisValue.length > 0) {
    // ensure it will properly evaluate to 
    // a regex correct item
    thisListBox.appendItem(thisValue, thisValue);
    thisArray.splice(thisArray.length, 0, thisValue.safeForRegEx());
  }
}

function doListItemSelection() {
  var thisListBox=getWhichBlacklistControl();
  if (thisListBox.selectedIndex > -1) {
    document.getElementById('btnRemoveListItem').disabled=false;
  } else {
    document.getElementById('btnRemoveListItem').disabled=true;
  }  
}

function btnRemoveSEListItemOnClick() {
  var thisListBox=document.getElementById('lstSearchEngines')
  if (thisListBox.selectedIndex > -1) {
    KnownSearchEnginePrefixes.splice(thisListBox.selectedIndex, 1);
    thisListBox.removeItemAt(thisListBox.selectedIndex);
  }
}

function btnAddSEListItemOnClick() {
  var thisListBox=document.getElementById('lstSearchEngines')
  var thisTextBox=document.getElementById('txtNewSEListItem');
  var thisValue=thisTextBox.value;
  if (thisValue.length > 0) {
    thisListBox.appendItem(thisValue, thisValue);
    KnownSearchEnginePrefixes.splice(KnownSearchEnginePrefixes.length, 0, thisValue.safeForRegEx());
  }
}

function doSEListItemSelection() {
  var thisListBox=document.getElementById('lstSearchEngines')
  if (thisListBox.selectedIndex > -1) {
    document.getElementById('btnRemoveSEListItem').disabled=false;
  } else {
    document.getElementById('btnRemoveListItem').disabled=true;
  }  
}

function btnAddSpecialPersonalOnClick() {
  window.openDialog('chrome://qthtoolbar/content/specialblacklist.xul', 'Personal Information Blacklist', 'chrome=yes,modal=yes,status=no', this, PersonalBLItemsRegex);
}

