//global variables
var lemurlog_g_enable = true;
var lemurlog_g_recordable = false;

var lemurlog_prev_scroll_time = 0;
var lemurlog_prev_blur_time = 0;
var lemurlog_prev_show_time = 0;
var lemurlog_prev_hide_time = 0;
var lemurlog_prev_ctrlc_time = 0;

var lemurlog_prev_focus_url = null;
var lemurlog_prev_load_url = null;

var lemurlog_ctrlc_down = false;

var lemurlog_search_urls = new Array();

var lemurlog_upload_service = null;

// support for private browsing
var inPrivateBrowseMode=false;
var isLoggingInPrivate=true;

///////////////////////////////////////////////////////////////////////
// Handler for writing to the log - checking for auto uploads
///////////////////////////////////////////////////////////////////////
function lemurlog_DoWriteLogFile(fileName, text) {
  lemurlog_WriteLogFile(fileName, text);
  lemurlog_checkAutoUpload();
}

function lemurlog_checkAutoUpload() {
  if (LemurLogToolbarConfiguration._isCurrentlyUploading) { return; }
  
  LemurLogToolbarConfiguration._isCurrentlyUploading=true;
  
  // see if we are using auto uploads in the configuration
  if (LemurLogToolbarConfiguration._serverBaseURL!="" && LemurLogToolbarConfiguration._serverAllowAutoUploads && LemurLogToolbarConfiguration._useAutomaticUploads) {
  
    // get the current unix time
    var currentDate = new Date; // Generic JS date object
    var unixtime_ms = currentDate.getTime(); // Returns milliseconds since the epoch
    
    // see if it's time for an upload
    if (LemurLogToolbarConfiguration._nextTimeToAutoUpload < unixtime_ms) {
      // it's time!
      // do we need to ask the user first?
      if (LemurLogToolbarConfiguration._askWhenUsingAutoUploads) {
      
        // yes - check and see
        var currentTime=new Date;
        var currentTimeMs=currentTime.getTime();
        var nextTimeToAutoUpload=currentTimeMs + LemurLogToolbarConfiguration._autoUploadIntervalTime;
        
        var nextUploadTimeSec=new Date(nextTimeToAutoUpload);
        var nextUploadTimeStr=nextUploadTimeSec.toString();
        
        var userConfirm=window.confirm(
          "An automatic upload of toolbar data is scheduled to run now.\n" + 
          "(If you cancel, the next upload is scheduled for: " + nextUploadTimeStr + "\nProceed?"
        );

        if (userConfirm) {
          lemurlog_DoActualUpload_Log();
        } else {
          // user clicked cancel
          LemurLogToolbarConfiguration.setNextAutomaticUploadTime();
          LemurLogToolbarConfiguration.saveLocalUserConfiguration();
          LemurLogToolbarConfiguration._isCurrentlyUploading=false;
          return;
        }
      } else {
        // no - don't need user input to auto-upload
        lemurlog_DoActualUpload_Log();
      }
    }
  } else {
    LemurLogToolbarConfiguration._isCurrentlyUploading=false;
  }
}

///////////////////////////////////////////////////////////////////////
// performs the upload of log files to remote server w/out prompt
///////////////////////////////////////////////////////////////////////
function lemurlog_DoActualUpload_Log()
{
  // before uploading - scrub the log files
  // remember to remove any search results that match
  // a query where any query term is blacklisted...
  
  lemurlog_upload_service = new lemurlog_uploadService();
  window.openDialog("chrome://qthtoolbar/content/upload.xul", "LogTB-Upload", "chrome=yes,modal=no,centerscreen=yes,status=no,height=400,width=600", window);
}


///////////////////////////////////////////////////////////////////////
// Upload log files to remote server
///////////////////////////////////////////////////////////////////////
function lemurlog_Upload_Log(event)
{
  var result = confirm("Would you like to upload log files?");
  if(!result)
  {
    return;
  }
  
  lemurlog_DoActualUpload_Log();
}

function lemurlog_showsettings(event) {
  window.openDialog('chrome://qthtoolbar/content/settings.xul', 'Log Toolbar Settings', 'chrome=yes,modal=yes,status=no', LemurLogToolbarConfiguration);
}


///////////////////////////////////////////////////////////////////////
// display help page
///////////////////////////////////////////////////////////////////////
function lemurlog_Help(event)
{
  lemurlog_LoadURL("http://www.lemurproject.org/querylogtoolbar/docs/client/");
}

///////////////////////////////////////////////////////////////////////
// 'keyup' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnKeyUp(event)
{

  if(!lemurlog_g_enable || !lemurlog_g_recordable || event.keyCode !== 67 || !lemurlog_ctrlc_down)
  {
    return;
  }
  var time = new Date().getTime();
  if(time - lemurlog_prev_ctrlc_time > 1000)
  {
    return;
  }
  lemurlog_ctrlc_down = false;//reset

  //The clipboard is (usually) ready when 'keyup', it's not ready when 'keydown' or 'keypress'

  var clipboard = Components.classes["@mozilla.org/widget/clipboard;1"].getService(Components.interfaces.nsIClipboard);
  if (!clipboard) 
  {
    return;
  } 
  var trans = Components.classes["@mozilla.org/widget/transferable;1"].createInstance(Components.interfaces.nsITransferable); 
  if (!trans) 
  {
    return;
  }
  trans.addDataFlavor("text/unicode"); 
  clipboard.getData(trans, clipboard.kGlobalClipboard); 
  var str = new Object(); 
  var strLength = new Object(); 
  trans.getTransferData("text/unicode", str,strLength); 
  if (str)
  {
    str = str.value.QueryInterface(Components.interfaces.nsISupportsString);
  }
  var text="";
  if (str) 
  {
    // text = str.data.substring(0,strLength.value / 2); 
    text = str.data.substring(0); 
  }
  //remove repeated spaces
  text = washAndRinse(lemurlog_TrimString(text));

  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "CtrlC\t" + time +"\t"+ text.length +"\t" + text +"\n");
} 

///////////////////////////////////////////////////////////////////////
// 'keydown' event handler
// event.keyCode for keydown and keyup (case insensitive)
// event.charCode for keypress (case sensitive)
// event.which for all
// keyCode of C = 67, charCode of C = 67, charCode of c = 99
///////////////////////////////////////////////////////////////////////
function lemurlog_OnKeyDown(event)
{

  if(!lemurlog_g_enable || !lemurlog_g_recordable)
  {
    return;
  }
  if(!event.ctrlKey || event.keyCode !== 67)
  {
    return;
  }
  var time = new Date().getTime();
  if(time - lemurlog_prev_ctrlc_time < lemurlog_MIN_INTERVAL)
  {
    lemurlog_prev_ctrlc_time = time;
    return;
  }
  lemurlog_prev_ctrlc_time = time;
  lemurlog_ctrlc_down = true;
}

///////////////////////////////////////////////////////////////////////
// 'mousedown' event handler
// record mousedown(left/middle/right) on a hyperlink
///////////////////////////////////////////////////////////////////////
function lemurlog_OnMouseDown(event)
{

  if(lemurlog_g_enable === false)
  {
    return;
  }
  var url = this.href;
  if(!lemurlog_IsRecordableURL(url))
  {
    return;
  }
  var time = new Date().getTime();
  url = washAndRinse(lemurlog_TrimString(url));

  switch(event.button)
  {
    case 0:
      lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "LClick\t" + time +"\t"+ url +"\n");
      break;
    case 1:
      lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "MClick\t" + time +"\t"+ url +"\n");
      break;
    case 2:
      lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "RClick\t" + time +"\t"+ url +"\n");
      break;
    default:
  }
}

///////////////////////////////////////////////////////////////////////
// when a tab is added
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabAdded_15(event)
{
  if (event.relatedNode !== gBrowser.mPanelContainer)
  {
    return; //Could be anywhere in the DOM (unless bubbling is caught at the interface?)
  }
  if(lemurlog_g_enable === false)
  {
    return;
  }

  if (event.target.localName == "vbox")// Firefox
  { 
    var time = new Date().getTime();
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "AddTab\t" + time + "\n");
  }
}

///////////////////////////////////////////////////////////////////////
// when a tab is removed
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabRemoved_15(event)
{
  if (event.relatedNode !== gBrowser.mPanelContainer)
  {
    return; //Could be anywhere in the DOM (unless bubbling is caught at the interface?)
  }
  if(lemurlog_g_enable === false)
  {
    return;
  }
  if (event.target.localName == "vbox")// Firefox
  { 
    var time = new Date().getTime();
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "RmTab\t" + time + "\n");
  }
}


///////////////////////////////////////////////////////////////////////
// when a tab is selected
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabSelected_15(event)
{
  if(lemurlog_g_enable === false)
  {
    return;
  }
  var url = window.content.location.href; 
  if(lemurlog_IsRecordableURL(url))
  {
    var time = new Date().getTime();
    url=washAndRinse(url, true);
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "SelTab\t" + time + "\t" + url + "\n");
  }
}

///////////////////////////////////////////////////////////////////////
// when a tab is added
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabAdded_20(event)
{
  if(lemurlog_g_enable === false)
  {
    return;
  }
  var time = new Date().getTime();
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "AddTab\t" + time + "\n");
}

///////////////////////////////////////////////////////////////////////
// when a tab is removed
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabRemoved_20(event)
{
  if(lemurlog_g_enable === false)
  {
    return;
  }
  var time = new Date().getTime();
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "RmTab\t" + time + "\n");
}


///////////////////////////////////////////////////////////////////////
// when a tab is selected
///////////////////////////////////////////////////////////////////////
function lemurlog_OnTabSelected_20(event)
{
  if(lemurlog_g_enable === false)
  {
    return;
  }

  var browser = gBrowser.selectedTab;
  if(!browser)
  {
    return;
  }
  var url = window.content.location.href; 
  if(lemurlog_IsRecordableURL(url))
  {
    var time = new Date().getTime();
    url=washAndRinse(url, true);
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "SelTab\t" + time + "\t" + url + "\n");
  }
}

///////////////////////////////////////////////////////////////////////
// 'focus' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnFocus(event) 
{
  lemurlog_SetButtons();

  if(lemurlog_g_enable === false)
  {
    return;
  }

  var time = new Date().getTime();
  
  if ((typeof(event.originalTarget)!="undefined") && (typeof(event.originalTarget.location)!="undefined")) {

    var url = event.originalTarget.location.href;

    if(url == lemurlog_prev_focus_url)
    {
      return;
    }
    lemurlog_prev_focus_url = url;
    if(lemurlog_IsRecordableURL(url))
    {
      lemurlog_g_recordable = true;
    }
    else
    {
      lemurlog_g_recordable = false;
      return;
    }
    url=washAndRinse(url, true);
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Focus\t" + time + "\t" + url + "\n");
  }

}

///////////////////////////////////////////////////////////////////////
// 'blur' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnBlur(event) 
{

  if(!lemurlog_g_enable || !lemurlog_g_recordable)
  {
    return;
  }
  lemurlog_prev_focus_url = null;//reset
  var time = new Date().getTime();
  if(time - lemurlog_prev_blur_time < lemurlog_MIN_INTERVAL)
  {
    lemurlog_prev_blur_time = time;
    return;
  }
  lemurlog_prev_blur_time = time;
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Blur\t" + time + "\n");
}

///////////////////////////////////////////////////////////////////////
// 'scroll' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnScroll(event) 
{
  if(lemurlog_g_enable === false || lemurlog_g_recordable === false)
  {
    return;
  }

  var time = new Date().getTime();
  if((time - lemurlog_prev_scroll_time) < lemurlog_MIN_INTERVAL)
  {
    lemurlog_prev_scroll_time = time;
    return;
  }
  lemurlog_prev_scroll_time = time;
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Scroll\t" + time + "\n");
}

///////////////////////////////////////////////////////////////////////
// 'pageshow' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnShow(event) 
{
  lemurlog_SetButtons();
  if(lemurlog_g_enable === false)
  {
    return;
  }
  var time = new Date().getTime();

  var url = event.originalTarget.location.href;
  
  if(lemurlog_IsRecordableURL(url))
  {
    lemurlog_g_recordable = true;
  }
  else
  {
    lemurlog_g_recordable = false;
    return;
  }

  if(time - lemurlog_prev_show_time < lemurlog_MIN_INTERVAL)
  {
    lemurlog_prev_show_time = time;
    return;
  }
  lemurlog_prev_show_time = time;
  url=washAndRinse(url, true);
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Show\t" + time + "\t" + url + "\n");

}

///////////////////////////////////////////////////////////////////////
// 'pagehide' event handler
///////////////////////////////////////////////////////////////////////
function lemurlog_OnHide(event) 
{
  if(!lemurlog_g_enable || !lemurlog_g_recordable)
  {
    return;
  }
  var time = new Date().getTime();
  if(time - lemurlog_prev_hide_time < lemurlog_MIN_INTERVAL)
  {
    lemurlog_prev_hide_time = time;
    return;
  }
  lemurlog_prev_hide_time = time;
  lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Hide\t" + time + "\n");
}

///////////////////////////////////////////////////////////////////////
// Turn on/off logging by switching the value of lemurlog_g_enable 
///////////////////////////////////////////////////////////////////////
function lemurlog_Switch(event, mode)
{
  // don't allow switch if we're in private browse mode!
  if (!inPrivateBrowseMode) {
    var time = new Date().getTime();
    
    lemurlog_g_enable = mode;
    if(mode === true)
    {
      lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "StartLogging\t" + time + "\n");
    }
    else
    {
      lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "PauseLogging\t" + time + "\n");
    }
    lemurlog_SetButtons();
  }
}

///////////////////////////////////////////////////////////////////////
// 'load' event handler in capture phase
// initialize
///////////////////////////////////////////////////////////////////////
function lemurlog_OnLoad_Cap(event) 
{
  //log load events
  if(lemurlog_g_enable === false)
  {
    return;
  }

  if ((typeof(event.originalTarget)!="undefined") && (typeof(event.originalTarget.location)!="undefined")) {
    var url = event.originalTarget.location.href;
    if(url == lemurlog_prev_load_url)
    {
      return;
    }
    lemurlog_prev_load_url = url;

    if(!lemurlog_IsRecordableURL(url))
    {
      // alert("LoadCapEvent - not recordable: " + url);
      return;
    }
    var time = new Date().getTime();
    var printableurl=washAndRinse(url, true);
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "LoadCap\t" + time + "\t" + printableurl + "\n");

    //add mousedown listeners to all links
    var links = window.content.document.links;
    if (links!="undefined") {
      for (i = 0; i < links.length; i++)
      {
        links[i].addEventListener('mousedown', lemurlog_OnMouseDown, true);
      }
    }

    //log search history
    // if it's a search URL and our last URL wasn't sanitized...
    if(lemurlog_IsSearchURL(url) && (printableurl.indexOf(sanitizedSubstitution) < 0)) 
    { 
      //save new  search results
      var found = false;
      var i;
      for(i = lemurlog_search_urls.length -1 ; i>=0; i--)
      {
        if(url == lemurlog_search_urls[i])
        {
          found = true;
          break;
        }

      }
      if(found === false)//new search url
      {
        var thisUrl=washAndRinse(url, true);
        lemurlog_search_urls[lemurlog_search_urls.length]=thisUrl;
        var html_content = washAndRinse(window.content.document.documentElement.innerHTML);
        lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "Search\t"+time+"\t"+html_content.length+"\n");
        lemurlog_DoWriteLogFile(lemurlog_PAGE_FILE, "LOGTB_BEGIN_SEARCH_PAGE\nID="+time+"\nURL="+thisUrl+"\nLength="+html_content.length+"\n<html>\n"+html_content+"\n</html>\n");
      }
    }
  }
}
///////////////////////////////////////////////////////////////////////
// 'load' event handler in bubbling phase
// initialize
///////////////////////////////////////////////////////////////////////
function lemurlog_OnLoad_Bub(event) 
{

  //log load events
  if(lemurlog_g_enable === false)
  {
    return;
  }

  var url = event.originalTarget.location.href;
  
  if(url == lemurlog_prev_load_url)
  {
    return;
  }
  lemurlog_prev_load_url = url;

  var time = new Date().getTime();
  if(lemurlog_IsRecordableURL(url))
  {
    url=washAndRinse(url, true);
    lemurlog_DoWriteLogFile(lemurlog_LOG_FILE, "LoadBub\t" + time + "\t" + url + "\n");
  }

}



///////////////////////////////////////////////////////////////////////
// View the log file with the browser
///////////////////////////////////////////////////////////////////////
function lemurlog_View_Log(event, log_id)
{
  var file;
  if(log_id == 0)
  {
    file = lemurlog_GetLogFile(lemurlog_LOG_FILE);
  }
  else if(log_id == 1)
  {
    file = lemurlog_GetLogFile(lemurlog_PAGE_FILE);
  }
  if(!file.exists())
  {
    file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE , 0644);
  }
  lemurlog_LoadURL("file:///" + file.path);
}

///////////////////////////////////////////////////////////////////////
// Remove all log files
///////////////////////////////////////////////////////////////////////
function lemurlog_Clear_Log(event)
{
  var result = confirm("Clear all log files?");
  if(!result)
  {
    return;
  }
  lemurlog_RemoveLogFile(lemurlog_LOG_FILE);
  lemurlog_RemoveLogFile(lemurlog_PAGE_FILE);
  // clear the search URLs
  lemurlog_search_urls=[];
}


// add support for private browsing - do not allow logging!

var privateBrowserListener = new PrivateBrowsingListener();  
privateBrowserListener.watcher = {  
  onEnterPrivateBrowsing : function() {  
    // we have just entered private browsing mode!
    isLoggingInPrivate=lemurlog_g_enable;
    lemurlog_Switch(null, false);
    
    // disable any buttons
    var button = document.getElementById("LogTB-Pause-Button");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Pause-Button-Gray");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Start-Button");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Start-Button-Gray");
    if (button) { button.disabled = true; }
    
    inPrivateBrowseMode=true;

  },  
   
  onExitPrivateBrowsing : function() {  
    // we have just left private browsing mode!  
    inPrivateBrowseMode=false;
    lemurlog_Switch(null, isLoggingInPrivate);
  }  
};


// see if we started in private browse mode
try {
  var pbs = Components.classes["@mozilla.org/privatebrowsing;1"].getService(Components.interfaces.nsIPrivateBrowsingService);
  var inPrivateBrowsingMode = pbs.privateBrowsingEnabled;  

  if (inPrivateBrowsingMode) {  
    // we are in private browsing mode!
    isLoggingInPrivate=lemurlog_g_enable;
    lemurlog_Switch(null, false);
    
    // disable any buttons
    var button = document.getElementById("LogTB-Pause-Button");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Pause-Button-Gray");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Start-Button");
    if (button) { button.disabled = true; }
    button = document.getElementById("LogTB-Start-Button-Gray");
    if (button) { button.disabled = true; }
    
    inPrivateBrowseMode=true;
  }  
} catch (ex) {
 // ignore exception for older versions
 //alert("Exception (Private Browse): " + ex.description);
}

//add listeners
// window.addEventListener('load', lemurlog_OnLoad_Cap, true);//if false, sometimes isn't triggerred
document.addEventListener('load', lemurlog_OnLoad_Cap, true);//if false, will fire just for the document - no frames
window.addEventListener('load', lemurlog_OnLoad_Bub, false);//if true, gBrowser is not ready yet

window.addEventListener('pageshow', lemurlog_OnShow, false);
window.addEventListener('pagehide', lemurlog_OnHide, false);

window.addEventListener('focus', lemurlog_OnFocus, true);//not bubbling
window.addEventListener('blur', lemurlog_OnBlur, true);//not bubbling

window.addEventListener('scroll', lemurlog_OnScroll, false);

window.addEventListener('keydown', lemurlog_OnKeyDown, false);
window.addEventListener('keyup', lemurlog_OnKeyUp, false);

// add tab listener
const lemurlog_appInfo = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULAppInfo);
const lemurlog_versionChecker = Components.classes["@mozilla.org/xpcom/version-comparator;1"].getService(Components.interfaces.nsIVersionComparator);
lemurlog_WriteLogFile(lemurlog_LOG_FILE, "FirefoxVersion\t" + lemurlog_appInfo.version + "\n");
window.setTimeout("lemurlog_AddTabEventListener();", 5000);

function lemurlog_AddTabEventListener()
{
  var lemurlog_tabContainer = null;
  if(lemurlog_versionChecker.compare(lemurlog_appInfo.version, "1.5") >= 0 && lemurlog_versionChecker.compare(lemurlog_appInfo.version, "2.0") < 0 ) {
    //initialize for tab listeners
    lemurlog_tabContainer = gBrowser.mPanelContainer;
    lemurlog_tabContainer.addEventListener("DOMNodeInserted", lemurlog_OnTabAdded_15, false);
    lemurlog_tabContainer.addEventListener("DOMNodeRemoved", lemurlog_OnTabRemoved_15, false);
    lemurlog_tabContainer.addEventListener("select", lemurlog_OnTabSelected_15, false);
  }
  else if(lemurlog_versionChecker.compare(lemurlog_appInfo.version, "2.0") >= 0)
  {
    lemurlog_tabContainer = gBrowser.tabContainer;
    lemurlog_tabContainer.addEventListener("TabOpen", lemurlog_OnTabAdded_20, false);
    lemurlog_tabContainer.addEventListener("TabClose", lemurlog_OnTabRemoved_20, false);
    lemurlog_tabContainer.addEventListener("TabSelect", lemurlog_OnTabSelected_20, false);
  }
}


///////////////////////////////////////////////////////////
// Supported log records:
///////////////////////////////////////////////////////////
// LoadCap
// LoadBub

// Show
// Hide

// Focus
// Blur

// AddTab
// SelTab
// RmTab

// LClick: left click 
// MClick: wheel click
// RClick: right click

// Scroll
// Ctrol-C

// Search
// 
