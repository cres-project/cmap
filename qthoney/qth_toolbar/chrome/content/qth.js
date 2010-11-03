(function(){
////////////////////////////////////////////////////////////////////////////////
// ライブラリ

    var dumpObj = function(target, label) {
        var str = "";
        for(var i in target) {
            try {
                str += i + "\n" + target[i] + "\n\n";
            } catch(e) {
                str += i + "\n??\n\n";
            }
        }
        debug_log(label+ "\n" + str);
    }



function http_get(url, after_func, post_data, headers) {
    debug_message(url)
    after_func = after_func || (function(result) { alert(result) })
    var method = post_data ? 'POST' : 'GET'

    var xmlHttpRequest = null;
    try {
        xmlHttpRequest = new XMLHttpRequest();
    } catch(e) {}

    if(!xmlHttpRequest)
        return;

    xmlHttpRequest.onreadystatechange = function() {
        if(4 == xmlHttpRequest.readyState) {
            after_func(xmlHttpRequest.responseText, xmlHttpRequest)
            xmlHttpRequest.onreadystatechange = function() {}
        }
    }
    try {
        xmlHttpRequest.open(method, url, true);
        if(post_data && headers['Content-Type'] == null) {
                    headers['Content-Type'] = 'application/x-www-form-urlencoded';
                }
        for(var key in headers)
            xmlHttpRequest.setRequestHeader(key, headers[key]);
                if(headers['Content-Type'] == 'application/octet-stream') {
                    xmlHttpRequest.sendAsBinary(post_data || null);
                } else {

                    xmlHttpRequest.send(post_data || null);
                }
    } catch(e) {}
}

function event_observe(
    target_element, event_name, observer_func, capture_or_bubbling) {
    target_element.addEventListener(
        event_name, observer_func, capture_or_bubbling || false);
}

function array_each(obj, func) {
    if('number' == typeof obj)
        for(var index = 0; index < obj; ++index) { if(func(index)) return; }
    else if(undefined != obj.length)
        for(var index2 = 0; index2 < obj.length; ++index2) {
            if(func(obj[index2], index2)) return;
        }
    else
        for(var name in obj) { if(func(obj[name], name)) return }
}

function array_each_result(array, init, func) {
    array_each(array, function(value, key) {
        var result = func(init, value, key);
        init = result[0];
        if(1 < result.length)
            return result[1];
        return false;
    })
    return init
}

function array_reduce(array, init, func) {
    return array_each_result(array, init,
        function(result, value, key) { return [func(result,value, key)]; }
    )
}

function array_map(array, func) {
    return array_reduce(array, [],
        function(results, value, key) {
            results.push(func(value, key)); return results;
        }
    )
}

function path_get_ifile(type) {
    return Components.classes['@mozilla.org/file/directory_service;1']
        .getService(Components.interfaces.nsIProperties)
        .get(type, Components.interfaces.nsIFile);
}

function path_get_profile_dir() {
    return path_get_ifile('ProfD');
}

function debug_log() {
    if(debug_log.release)
        return;

    if(!debug_log.count)
        debug_log.count = 0;
    
    var log = array_map(arguments,
        function(item){
            if('object' == typeof(item)) {
                var results = [];
                for(var key in item) {
                    try{
                        results.push('\t[' + key + ']=[' + item[key] + ']');
                    } catch(e) {
                        results.push('\t[' + key + ']=[ERROR]');
                    }
                }
                return item + ': {\n' + results.sort().join(',\n') + '\n}';
            }
            return '[' + item + ']';
        }
    );
    log = log.join(', ');
    log = 'debug_log(' + (debug_log.count++) + ') : ' + log;
    if(debug_log.dump) {
        dump(log + '\n');
    } else {
        if(!debug_log.console) {
            var nsIConsoleService = Components.interfaces.nsIConsoleService;
            debug_log.console = Components.classes['@mozilla.org/consoleservice;1']
                                .getService(nsIConsoleService);
        }
        debug_log.console.logStringMessage(log);
        if(toJavaScriptConsole && !debug_log.is_shown) {
            setTimeout(
                function() {
                    toJavaScriptConsole();
                    debug_log.show_console_id = null;
                }
            );
            debug_log.is_shown = true;
        }
    }
}

var debug_message = debug_log;

function config_get(key, default_value) {
    const nsIPrefBranch = Components.interfaces.nsIPrefBranch
    const prefBranch = Components.classes['@mozilla.org/preferences;1']
                                                    .getService(nsIPrefBranch)
    switch(prefBranch.getPrefType(key)) {
        case nsIPrefBranch.PREF_INVALID: return default_value || null;
        case nsIPrefBranch.PREF_INT: return prefBranch.getIntPref(key);
        case nsIPrefBranch.PREF_BOOL: return prefBranch.getBoolPref(key);
        case nsIPrefBranch.PREF_STRING:
            try {
                var result = prefBranch.getCharPref(key);
                var chrome_str = 'chrome://';
                if(chrome_str == result.substr(0, chrome_str.length)) {
                    return Components.classes['@mozilla.org/intl/stringbundle;1']
                        .getService(Components.interfaces.nsIStringBundleService)
                        .createBundle(result).GetStringFromName(key)
                } else
                    return result;
            } catch(e) {
                return default_value || null;
            }
    }
    return default_value || null;
}

debug_log.is_debug = config_get('extension.qth_toolbar.is_debug');
debug_log.is_develop = config_get('extension.qth_toolbar.is_develop');
debug_log.release = !(debug_log.is_debug || debug_log.is_develop);
if(!debug_log.release) {
    debug_log('debug mode')
}

function path_cd(ifile/*, args*/) {
    var args = array_create(arguments)
    var result = args.shift().clone()
    return array_reduce(
        args, result,
        function(result, item) { result.append(item); return result }
    )
}

function array_create(obj) {
    return array_map(obj, function(item) { return item })
}

function ifile_append(ifile, data) {
    var PR_WRONLY = 0x02;
    var PR_CREATE_FILE = 0x08;
    var PR_APPEND = 0x10

    var stream = Components
        .classes['@mozilla.org/network/file-output-stream;1']
        .createInstance(Components.interfaces.nsIFileOutputStream);
    stream.init(ifile, PR_WRONLY | PR_CREATE_FILE | PR_APPEND, 0600, false);
    try {
        stream.write(data, data.length);
    } finally {
        stream.close();
    }
}

function path_enable_dir(ifile) {
    if (!ifile.exists()) {
        ifile.create(Components.interfaces.nsIFile.DIRECTORY_TYPE, 0600);
    }
}

function path_enable(ifile) {
    path_enable_dir(ifile.parent)
}

function string_format(format, values) {
    function parse(format, reg_string, value) {
        var reg_format = '([#0 -+]*)([1-9][0-9]*)?(\\.[0-9]+)*([hlL]?)([diouxXeEfFgGcrs])';
        var matches = format.match(new RegExp(reg_string + reg_format));
        if(!matches)
            return format;
        var width = parseInt(matches[3]);
        if(!width)
            width = 6;
        if('i' == matches[5] || 'd' == matches[5])
            value = parseInt(value).toString();
        else if('o' == matches[5])
            value = parseInt(value).toString(8);
        else if('u' == matches[5])
            value = (0xffffffff - parseInt(value) + 1).toString();
        else if('x' == matches[5])
            value = parseInt(value).toString(16).toLowerCase();
        else if('X' == matches[5])
            value = parseInt(value).toString(16).toUpperCase();
        else if('e' == matches[5])
            value = parseFloat(value).toExponential(width).toLowerCase();
        else if('E' == matches[5])
            value = parseFloat(value).toExponential(width).toUpperCase();
        else if('g' == matches[5])
            value = parseFloat(value).toPrecision(4).toLowerCase();
        else if('G' == matches[5])
            value = parseFloat(value).toPrecision(4).toUpperCase();
        else if('f' == matches[5])
            value = parseFloat(value).toFixed(width).toLowerCase();
        else if('F' == matches[5])
            value = parseFloat(value).toFixed(width).toUpperCase();

        if(-1 != matches[1].indexOf('# ') && 'o' == matches[5] &&
                                             '0' != value.substr(0, 1))
            value = '0' + value;

        if('i' == matches[5] || 'd' == matches[5] || 'e' == matches[5] ||
           'E' == matches[5] || 'f' == matches[5] || 'F' == matches[5])
        {
            if('-' != value.substr(0,1)) {
                if(-1 != matches[1].indexOf('+')) {
                    value = '+' + value;
                } else if(-1 != matches[1].indexOf(' ')) {
                    value = ' ' + value;
                }
            }
        }

        if('i' == matches[5] || 'd' == matches[5] || 'o' == matches[5] ||
           'u' == matches[5] || 'x' == matches[5] || 'X' == matches[5] ||
           'f' == matches[5] || 'F' == matches[5])
        {
            if(-1 != matches[1].indexOf('0')) {
                while(value.length < matches[2]) {
                    value = '0' + value;
                }
            }
        }

        if(-1 != matches[1].indexOf('-')) {
            while(value.length < matches[2]) {
                value += ' ';
            }
        }
        return format.replace(matches[0], value);
    }
    if(values.length) {
        for(var index = 0; index < values.length; ++index) {
            format = parse(format, '%', values[index]);
        }
    } else {
        for(key in values) {
            format = parse(format, '%\\(' + key + '\\)', values[key]);
        }
    }
    return format;
}

function date_time_get_now_dict() {
    var now = new Date();
    return {
        'year': now.getFullYear(),
        'month': now.getMonth() + 1,
        'date': now.getDate(),
        'hour': now.getHours(),
        'min': now.getMinutes(),
        'sec': now.getSeconds(),
        'msec': now.getMilliseconds()
    }
}

function url_rel_to_abs(doc, path){
    var e = doc.createElement('span');
    e.innerHTML = '<a href="' + path + '" />';
    return e.firstChild.href;
}

function config_set(key, value) {
    //http://piro.sakura.ne.jp/xul/tips/x0007.html
    const nsIPrefBranch = Components.interfaces.nsIPrefBranch
    const prefBranch = Components.classes['@mozilla.org/preferences;1']
                                                    .getService(nsIPrefBranch)
    var setter = prefBranch.setCharPref;
    switch(typeof value) {
        case 'boolean': setter = prefBranch.setBoolPref; break;
        case 'number': setter = prefBranch.setIntPref; break;
    }
    try {
        setter(key, value)
    } catch(e) {
        prefBranch.clearUserPref(key)
        setter(key, value)
    }
}

function session_set(tab, key, value) {
    var nsISessionStore = Components.classes["@mozilla.org/browser/sessionstore;1"]
                            .getService(Components.interfaces.nsISessionStore);
    nsISessionStore.setTabValue(tab, key, value);
}

function session_get(tab, key, default_value) {
    var nsISessionStore = Components.classes["@mozilla.org/browser/sessionstore;1"]
                            .getService(Components.interfaces.nsISessionStore);
    return nsISessionStore.getTabValue(tab, key) || default_value;
}

function session_del(tab, key) {
    var nsISessionStore = Components.classes["@mozilla.org/browser/sessionstore;1"]
                            .getService(Components.interfaces.nsISessionStore);
    return nsISessionStore.deleteTabValue(tab, key);
}

function date_time_get_epoch() {
    return (new Date()).getTime();
}

function string_encode(string, src, dst) {
    var result = string.toString();
    var UConv = Components.classes['@mozilla.org/intl/scriptableunicodeconverter']
            .getService(Components.interfaces.nsIScriptableUnicodeConverter);
    if(src) {
        UConv.charset = src;
        result = UConv.ConvertToUnicode(result);
    }
    if(dst) {
        UConv.charset = dst;
        result = UConv.ConvertFromUnicode(result);
    }
    return result
}

function dict_update(target, arg) {
    for(var key in arg) {
        target[key] = arg[key];
    }
    return target;
}

function dict_get(dict, key, default_value)
{
    if(!(key in dict)) {
        return default_value
    }
    return dict[key]
}

function dom_get(id) {
    return document.getElementById(id)
}

function xpcom_get(component_id) {
    return Components.classes[component_id].getService().wrappedJSObject;
}

function dict_set_default(dict, key, default_value) {
    if(!(key in dict)) {
        dict[key] = default_value
    }
    return dict[key]
}

function function_wrap(original_func, wrap_func){
    return function(){
        return wrap_func.apply({original_func: original_func}, arguments);
    }
}

function url_split(url, characterSet) {
    var url_part = url.split('?')
    return [url_part.shift(), url_parse_query(url_part.join('?'), characterSet)]
}

function url_decode(target, characterSet) {
    target = string_encode(unescape(target), characterSet)
    return decodeURIComponent(target).replace('+', ' ');
}

function url_parse_query(queries, characterSet) {
    if(!queries) {
        return {}
    }
    return array_reduce(queries.split('&'), {}, 
        function(results, query, index) {
            var key_value = query.split('=')
            results[url_decode(key_value[0], characterSet)] = url_decode(key_value[1], characterSet);
            return results
        }
    )
}

function ifile_from_path(path) {
    var ifile = Components
        .classes['@mozilla.org/file/local;1']
        .createInstance(Components.interfaces.nsILocalFile);
    ifile.initWithPath(path);
    return ifile;
}

function ff_observe_startup(callback) {
    Components
        .classes["@mozilla.org/observer-service;1"]
        .getService(Components.interfaces.nsIObserverService)
        .addObserver({observe: callback}, "app-startup", false);
}

function ff_observe_quit(callback) {
    Components
        .classes["@mozilla.org/observer-service;1"]
        .getService(Components.interfaces.nsIObserverService)
        .addObserver({observe: callback}, "quit-application", false);
}

function ff_observe_examine_responce(callback) {
    Components
        .classes["@mozilla.org/observer-service;1"]
        .getService(Components.interfaces.nsIObserverService)
        .addObserver({observe: callback}, "http-on-examine-response", false);
}

function ff_observe_modify_request(callback) {
    Components
        .classes["@mozilla.org/observer-service;1"]
        .getService(Components.interfaces.nsIObserverService)
        .addObserver({observe: callback}, "http-on-modify-request", false);
}

function dom_get_children_by_tag_name(element, tag_name, results) {
    results = results || []
    array_each(element.childNodes,
        function(item) {
            if(tag_name == item.tagName) {
                results.push(item)
            } else {
                dom_get_children_by_tag_name(item, tag_name, results)
            }
        }
    )
    return results
}

function dom_insert_after(target, element) {
    if(!target.nextSibling) {
        target.parentNode.appendChild(element)
    } else {
        target.parentNode.insertBefore(element, target.nextSibling)
    }
}

function dom_create(name, attrs, children, events) {
    //ref $N in fastlookupalc.user.js
    attrs = attrs || {}; events = events || {}; children = children || []
    var result = document.createElement(name);
    for(var attr in attrs) {
        result.setAttribute(attr, attrs[attr])
    }
    for(var index = 0; index < children.length; ++index) {
        if('string' == typeof children[index]) {
            result.appendChild(document.createTextNode(children[index]))
        } else {
            result.appendChild(children[index])
        }
    }
    for(var event in events) {
        result.addEventListener(event, events[event], false)
    }
    return result
}

function json_decode(str){
    var nativeJSON = Components.classes["@mozilla.org/dom/json;1"].createInstance(Components.interfaces.nsIJSON);
    return nativeJSON.decode(str);
}

function string_encode(string, src, dst) {
    //エンコードが疑わしかったらencodeして値を見てみてテストする。
    var result = string.toString(); //汚染しないようにコピー
    var UConv = Components.classes['@mozilla.org/intl/scriptableunicodeconverter'].getService(Components.interfaces.nsIScriptableUnicodeConverter);
    if(src) {
        UConv.charset = src;
        //ACString→AString
        result = UConv.ConvertToUnicode(result);
    }
    if(dst) {
        UConv.charset = dst;
        //AString→ACString
        result = UConv.ConvertFromUnicode(result);
    }
    return result
}

function string_chop(string) {
    if('\n' == string[string.length-1] && '\r' == string[string.length-1]) {
        return string.substr(0, string.length-2);
    }
    return string.substr(0, string.length-1);
}

////////////////////////////////////////////////////////////////////////////////
// QTH実装

// まずlemurのログ関数をラップして、lemurのイベントをフックする。
lemurlog_WriteLogFile = function_wrap(lemurlog_WriteLogFile, function(fileName, text) {
    on_lemur_event(text);
    this.original_func(fileName, text);
});

// lemurのログ関数のフックハンドラ。lemurのイベントのうち、使えるものは使う。

var w_add_tab_count = 1;    // 追加されて、ページのロードが終わっていないタブの数

function on_lemur_event(original_log) {
    // ログ用の辞書を用意
    var log = {'original_log': original_log}

    // イベントラベルをチェック
    switch(original_log.split('\t')[0]) {
        case 'StartLogging': log['event_label'] = 'start'; break;
        case 'PauseLogging': log['event_label'] = 'end'; break;
        case 'Focus': log['event_label'] = 'focus'; break;
        case 'Scroll': log['event_label'] = 'scroll'; break;
        case 'AddTab':
            // load/showでタブを解決するためのフラグを立てる。
            w_add_tab_count++;
            return;
        //処理しない。
        case 'CtrlC': //log['event_label'] = 'copy'; break; //-> 自前で取る。
        case 'RmTab': //log['event_label'] = 'close'; break; //-> 自前で取る。
        case 'SelTab': //log['event_label'] = 'change'; break;    //-> 独自に検出するので処理しない。
        case 'Blur': //log['event_label'] = 'blur'; break; //->記録しない
        case 'Show':
        case 'Hide':
        case 'RClick':
        case 'LClick':
        case 'MClick':
        case 'Search':
        case 'LoadCap':
            return;
        default: return;
    }

    // ログデータを作成
    append_log(build_log(log))

    //この後、従来通りlemurのログも保存される
}

// qth専用で、全てのウインドウ共有の辞書を取得
var currentBrowserInitialized = false;
function get_globals() {
    var qth_globals = xpcom_get('@kyagroup.com/qth_toolbar/singleton_object;1');

    // 起動直後の場合は初期化しておく
    if(!qth_globals.is_initialized) {

        // sessionstore.js 読み出し
        var sessionstore_ifile = path_cd(path_get_profile_dir(), 'sessionstore.js');
        var data = "";
        var fstream = Components.classes["@mozilla.org/network/file-input-stream;1"]
                                .createInstance(Components.interfaces.nsIFileInputStream);
        var sstream = Components.classes["@mozilla.org/scriptableinputstream;1"]
                                .createInstance(Components.interfaces.nsIScriptableInputStream);
        var sessionstore;
        try {
            fstream.init(sessionstore_ifile, -1, 0, 0);
            try {
                sstream.init(fstream); 
                var str = sstream.read(4096);
                while (str.length > 0) {
                  data += str;
                  str = sstream.read(4096);
                }
                //sessionstore = eval(data);
                var sessionstore_utf8 = string_encode(data, 'UTF-8', null); // 'UTF-8');
                sessionstore = eval(sessionstore_utf8);
            } catch(e){
                debug_log(e);
            }
            sstream.close();
        } catch(e) {
            sessionstore = null;
        }
        fstream.close();

        // タブの通し番号用変数が初期化されていなければ0に初期化
        qth_globals.tab_count = 0;
        // changeイベント用の前回アクティブだったタブId用変数を0に初期化
        qth_globals.pre_tab_id = 0;
        // タブの付帯データ辞書もなければ初期化
        qth_globals.tabs = {};
        qth_globals.pre_search_data = default_search_data();

        qth_globals.window_count = 0;

        qth_globals.is_initialized = true;
        qth_globals.on_submit = null;
        
        qth_globals.debug_log = debug_log;
        qth_globals.prompt = prompt;
        qth_globals.http_get = http_get;
        
        // 初回起動時イベントを記録
        append_log(build_log({'event_label': 'start'}));


        // QTH のバージョンを記録
        var em = Components.classes["@mozilla.org/extensions/manager;1"]
          .getService(Components.interfaces.nsIExtensionManager);
        var addon = em.getItemForID("{199d5ba0-9736-46f8-99d9-424d1cd9ed1a}");
        var qth_version = addon.version;

        append_log2({
            'eventType'       : 'init_qth',
            'startup_page'    : config_get('browser.startup.page'),
            'startup_homepage': config_get('browser.startup.homepage'),
            'prev_session'    : sessionstore,
            'qth_version'     : qth_version,
        });
        
        // httpリクエストにアタッチする
        ff_observe_modify_request(
            function(subject, topic, data){
                if(qth_globals.on_submit) {

                    // データをキャスト
                    subject.QueryInterface(Components.interfaces.nsIHttpChannel);
                    
                    // メソッドが等しいこと。
                    var method = qth_globals.on_submit['method'];
                    if(!method){ method = 'GET'; }
                    method = method.toUpperCase();
                    if(subject.requestMethod != method) {
                        return 
                    }

                    // URLが等しいこと
                    // GETならURLを分割する。
                    var url = subject.name;
                    if('GET' == method) {
                        var splitted = url.split('?');
                        url = splitted.shift()
                        qth_globals.on_submit['submit_options'] = splitted.join('?')
                    } else if('POST') {
                        //読み込む
                        subject.QueryInterface(Components.interfaces.nsIUploadChannel);
                        var upload_stream = subject.uploadStream;
                        upload_stream.QueryInterface(Components.interfaces.nsISeekableStream);
                        var input_stream = Components.classes["@mozilla.org/scriptableinputstream;1"]
                            .createInstance(Components.interfaces. nsIScriptableInputStream);
                        input_stream.init(upload_stream);
                        upload_stream.seek(0, 0);
                        var length = input_stream.available();
                        qth_globals.on_submit['submit_options'] = input_stream.read(length);
                        upload_stream.seek(0, 0);

                        var splitted = qth_globals.on_submit['submit_options'].split('\r\n\r\n')
                        splitted.shift()
                        qth_globals.on_submit['submit_options'] = splitted.join('\r\n\r\n')
                    }

                    if(url != qth_globals.on_submit['submit_action_url']) {
                        return;
                    }

                    append_log(build_log(qth_globals.on_submit));
                    qth_globals.on_submit = null;
                }
            }
        );

        // expr
        try {
            const windowManagerID = '@mozilla.org/appshell/window-mediator;1';
            const windowManagerIF = Components.interfaces.nsIWindowMediator;
            const windowManager   = Components.classes[windowManagerID].getService(windowManagerIF);

            ////////////////////////////////

            var attachEventHandlers = function(targetWindow) {
                try {
                    var docshell = targetWindow.docShell;
                    if(!docshell) {
                        return;
                    }

                    var requestor = docshell.QueryInterface(Components.interfaces.nsIInterfaceRequestor);
                    var win = requestor.getInterface(Components.interfaces.nsIDOMWindow);

                    var logClipboard = function(event) {
                        const nsIClipboard = Components.interfaces.nsIClipboard;
                        const f = function(){
                            try {
                                var clip = Components.classes["@mozilla.org/widget/clipboard;1"].getService(nsIClipboard);
                                var trans = Components.classes["@mozilla.org/widget/transferable;1"].createInstance(Components.interfaces.nsITransferable);
                                trans.addDataFlavor("text/unicode");
                                clip.getData(trans, clip.kGlobalClipboard);

                                var text = new Object();
                                var len = new Object();

                                trans.getTransferData("text/unicode", text, len);

                                var clipboardStr;
                                if (text) {
                                    text = text.value.QueryInterface(Components.interfaces.nsISupportsString);
                                    if(text) {
                                        clipboardStr = text.data.substring(0, len.value / 2);
                                    }
                                }

                                var log = {
                                    'eventType'        : event.type,
                                    'target_toString'    : event.target.toString(),
                                    'clipboard_toString' : clipboardStr
                                }
                                append_log2(log, event.originalTarget.linkedPanel);

                            } catch(E) {
                                debug_log(E);
                            }
                        }
                        setTimeout(f);
                    }

                    // key関連 のイベントハンドラ
                    var key_event = function(e) {

                        try {
                            var log = {
                                'eventType': e.type,
                                'keycode':   e.keyCode, 
                                'modifiers': modifier_keys(e)
                            }
                            if(e.target instanceof HTMLElement) {
                                log['target'] = e.target.toString();
                            }
                            append_log2(log, e.originalTarget.linkedPanel);
                        } catch (err) {
                            debug_log(err);
                        }
                    } 

                    // mouse関連 のイベントハンドラ
                    var mouse_event = function(e) {
                        var log = {
                            'eventType' : e.type,
                            'button'    : e.button, 
                            'modifiers': modifier_keys(e)
                        }
                        if(e.target instanceof HTMLElement) {
                            log['target'] = e.target.toString();
                        }
                        append_log2(log, e.originalTarget.linkedPanel);
                    } 

                    // focus 関連のイベントハンドラ
                    var focus_event = function(e) {
                        append_log2({'eventType':e.type, 'target_toString':e.target.toString()});
                    }

                    // popup関連 のイベントハンドラ
                    var popup_event = function(e) {
                        var log = {
                            'eventType'     : e.type,
                            'target_toString' : e.target.toString(),
                        };
                        append_log2(log, e.originalTarget.linkedPanel);
                    } 

                    const events = {
                        'command': function(e) {
                            var log = {
                              'eventType'   : 'command',
                              'target_id'    : e.target.id,
                              'target_label' : e.target.label,
                              'original_target_id'    : e.originalTarget.id,
                              'original_target_label' : e.originalTarget.label,
                            };

                            if(e.target.id == 'editBookmarkPanelDoneButton') {
                                try{
                                    log['bookmark_title'] = e.currentTarget.document.getElementById('editBMPanel_namePicker').value;
                                    log['bookmark_url']   = e.currentTarget.document.location.href;
                                } catch(err) {
                                    debug_log(err);
                                }
                            }

                            append_log2(log);
                        },

                        //'pageshow': function(e) {
                        //    // appcontent 側で取得する
                        //},

                        //'pagehide': function(e) {
                        //    // appcontent 側で取得する
                        //},

                        'submit': function(e) {
                            var log = {
                                'eventType'   : e.type,
                                'form_id'     : e.target.getAttribute('id'),
                                'form_name'   : e.target.getAttribute('name'),
                                'form_action' : e.target.getAttribute('action'),
                            };
                            append_log2(log, e.originalTarget.linkedPanel);
                        },

                        'contextmenu' : function(e) {
                            var log = {
                                'eventType': e.type,
                            }
                            if(e.target instanceof HTMLElement) {
                                log['target_toString'] = e.target.toString();
                            }
                            append_log2(log, e.originalTarget.linkedPanel);
                        },

                        'drop' : function(e) {
                            var log = {
                                'eventType': e.type,
                            }
                            if(e.target instanceof HTMLElement) {
                                log['drop_toString'] = e.target.toString();
                            }
                            log['target_toString'] = e.dataTransfer.types.toString();
                            append_log2(log, e.originalTarget.linkedPanel);
                        },

                        'click': function(e) {
                            var target_window = windowManager.getMostRecentWindow('navigator:browser');
                            var linked_panel  = target_window.getBrowser().selectedTab.linkedPanel;

                            var target_node = e.target;
                            var target_node_outerHTML = '';
                            try {
                                var doc = target_node;
                                while(true) {
                                    if(doc instanceof HTMLDocument) {
                                        break;
                                    }
                                    doc = doc.parentNode;
                                    if(doc == null) {
                                        break;
                                    }
                                }

                                target_node_outerHTML = doc.createElement('div').
                                    appendChild(target_node.cloneNode(true)).parentNode.innerHTML;
                            } catch (e) {
                                debug_log(e+"\n"+e.target);
                            }

                            var log = {
                                'event_label' : 'click',
                                'target'      : e.target.toString(),
                                'target_id'   : e.target.id,
                                'button'      : e.button,
                                'documentURI' : e.target.documentURI,
                                //'innerHTML'   : e.target.innerHTML,
                                'outerHTML'   : target_node_outerHTML, //e.target.outerHTML,
                                'modifiers'   : modifier_keys(e),
                            };

                            if(e.target instanceof HTMLInputElement) {
                                log['type'] = e.target.type;
                            } else if(e.target instanceof HTMLElement) {
                                var target_node = e.target;
                                while(true) {
                                    if(target_node.tagName == 'A') break;
                                    target_node = target_node.parentNode;
                                    if(!target_node) break;
                                }

                                if(target_node) {
                                    try {
                                        var doc = target_node;
                                        while(true) {
                                            if(doc instanceof HTMLDocument) {
                                                break;
                                            }
                                            doc = doc.parentNode;
                                            if(doc == null) {
                                                break;
                                            }
                                        }

                                        var x = doc.createElement('div').
                                        appendChild(target_node.cloneNode(true)).parentNode.innerHTML;
                                        log['anchor_outerHTML'] = x;
                                    } catch (e) {
                                        debug_log(e);
                                    }
                                    log['anchor_href']      = target_node.getAttribute('href');
                                }
                            }

                            try{
                                append_log2(log, linked_panel);
                            } catch(err) {
                                debug_log(err);
                            }
                        },

                        'focus'       : focus_event,
                        'focusout'    : focus_event,
                        'blur'        : focus_event,
                        'keydown'     : key_event,
                        'keyup'       : key_event,
                        'mousedown'   : mouse_event,
                        'mouseup'     : mouse_event,
                        'dblclick'    : mouse_event,
                        'popuphidden' : popup_event,
                        'popuphiding' : popup_event,
                        'popupshown'  : popup_event,

                        'abort' : function(e){
                            append_log2({'eventType':'abort'});
                        },
                        'error' : function(e){
                            append_log2({'eventType':'error'});
                        },

                        'TabSelect': function(e) {
                            append_log2({
                                'eventType': e.type, 
                                'tab_url'  : e.target.mCurrentBrowser.currentURI.spec
                            }, e.originalTarget.linkedPanel);
                        },

                        'cut': function(e) {
                            logClipboard(e)
                        },

                        'paste': function(e) {
                            logClipboard(e)
                        },

                        'copy': function(e) {
                            logClipboard(e)
                        },
                    };

                    for(var ev in events) {
                        win.addEventListener(ev, events[ev], true/*capture*/);
                    }

                    ////////////////////////////////
                } catch (E) {
                    debug_log(E);
                }
            };


            windowManager.addListener({
                QueryInterface: function(iid) {
                   if (iid.equals(Components.interfaces.nsIWindowMediatorListener) ||
                       iid.equals(Components.interfaces.nsISupports)) {
                       return this;
                   }
                   alert(iid);
                   throw Components.results.NS_ERROR_NO_INTERFACE;
                },

                onWindowTitleChange: function(){
                },

                onOpenWindow: function(aWindow) {
                    attachEventHandlers(aWindow);

                },
                onCloseWindow: function(aWindow) {
                    var docshell = aWindow.docShell
                    var requestor = docshell.QueryInterface(Components.interfaces.nsIInterfaceRequestor);
                    var win = requestor.getInterface(Components.interfaces.nsIDOMWindow);
                    var targetBrowser = win.document.defaultView.getBrowser();

                    append_log2({'eventType':'close', 'eventType':'onCloseWindow'}, targetBrowser.selectedTab.linkedPanel);
                    // TODO onCloseWindow をどう記録しておくか

                }
           });

            var windows = windowManager.getXULWindowEnumerator(null);
            while(windows.hasMoreElements()) {
                var w = windows.getNext();
                attachEventHandlers(w);
            }
        } catch(E) {
            debug_log(E);
        }

        ////////////////////////////////
        // external search toolbar
        try {
            BrowserSearch.org_loadSearch = BrowserSearch.loadSearch;
            BrowserSearch.loadSearch = function(searchText, useNewTab) {
                BrowserSearch.org_loadSearch(searchText, useNewTab);
            };
        } catch(E) {
            debug_log(E);
        }

        ////////////////////////////////
        // internal search toolbar
        try {
            gFindBar.orig__find = gFindBar._find;
            gFindBar._find = function(x) {
                gFindBar.orig__find(x);
                append_log2({'eventType':'_find', 'find_text':gFindBar._findField.value});
            };
        }catch(E){
            debug_log(E);
        }
    }
    return qth_globals
}

var tab_id2document = {};

// ログ文字列作成用のパラメータを作って返す。
// ログ項目のデフォルト値を持った辞書を作成する。
// 作成した辞書に、引数の辞書で上書きしたものを返す。
function build_log(log_option, doc, tab_id) {
    tab_id = tab_id || get_current_tab_id();

    // そのIDに紐づいたデータ辞書を取得
    var tab_data = get_tab_data(tab_id);

    // documentを更新
    tab_data.doc = doc = (doc || tab_data.doc || gBrowser.contentDocument);

    if(!doc.location) {
        if(gBrowser.contentDocument.location) {
            tab_data.doc = doc = gBrowser.contentDocument;
        } else {
            return;
        }
    }

    tab_id2document[tab_id] = doc;

    // ログ用の辞書を用意
    var log = {};

    // アクティブなタブのIDを取得
    log['tab_id'] = tab_id;

    // もし、前回のログ保存時からtab_idが変わっていたらchangeイベントを発行する。
    if(get_globals().pre_tab_id != log['tab_id']) {
        get_globals().pre_tab_id = log['tab_id'];
        append_log(build_log({'event_label': 'change'}, doc, log['tab_id']));
    }

    // 現在の日時を示す文字列を作成して記録
    var date_format = '%(year)04d%(month)02d%(date)02d%(hour)02d%(min)02d%(sec)02d.%(msec)04d';
    log['date_str'] = string_format(date_format, date_time_get_now_dict());

    log['session_time'] = date_time_get_epoch() - tab_data.created;

    // URLやタイトルを記録
    log['title'] = doc.title;
    log['url'] = doc.location.href;

    // ページIDを取得
    log['page_id'] = get_page_id(tab_data, log['url'], doc);

    // 検索結果かどうかを判定
    log = dict_update(log, extract_search_data(log['url'], doc))

    // デフォルト値を設定
    log['anchor_text'] = '';
    log['next_url'] = '';
    log['next_page_id'] = '';
    log['source_name'] = '';

    log['bookmark_title'] = '';
    log['submit_options'] = '';
    log['submit_action_url'] = '';

    return dict_update(log, log_option);
}

function sanitize(target) {
    return target.replace(/[\n\r\t]/g, ' ');
}

function extract_search_data(url, doc) {
    var splitted_url = url_split(url, doc.characterSet);
    
    if(!get_globals().search_engines) {
        var search_ifile = path_cd(path_get_profile_dir(), 'QT', 'qth_search_list.json');

        var data = "";
        var fstream = Components.classes["@mozilla.org/network/file-input-stream;1"]
                                .createInstance(Components.interfaces.nsIFileInputStream);
        var sstream = Components.classes["@mozilla.org/scriptableinputstream;1"]
                                .createInstance(Components.interfaces.nsIScriptableInputStream);
        try {
            fstream.init(search_ifile, -1, 0, 0);
            try {
                sstream.init(fstream); 
                var str = sstream.read(4096);
                while (str.length > 0) {
                  data += str;
                  str = sstream.read(4096);
                }
                get_globals().search_engines = json_decode(data);
            } catch(e){
            }
            sstream.close();
        } catch(e) {
            get_globals().search_engines = [];
        }
        fstream.close();
        
        if(!get_globals().search_engines.length) {
            http_get('http://mew.ntcir.nii.ac.jp/qth_toolbar/qth_search_list.json',
                function(result) {
                    get_globals().search_engines = json_decode(result);
                    if(get_globals().search_engines.length)
                        ifile_append(search_ifile, result);
                }
            )
        }
    }

    var search_engines = get_globals().search_engines;

    for(var i = 0; i < search_engines.length; i++) {
        var search_engine = search_engines[i];
        var matched = splitted_url[0].match(search_engine['base_url'])
        if(matched) {
            var result = {
                'search_label': search_engines[i]['search_label'],
                'page_kind': 'search_result_page',
                'result_item_index': dict_get(splitted_url[1], search_engines[i]['index_key'], 0),
                'index_key': search_engines[i]['index_key']
            };

            if('in_url' == search_engine['keyword_type']) {
                result['keyword'] = url_decode(
                    matched[search_engine['keyword_index']], doc.characterSet);
            } else if('parameter' == search_engine['keyword_type']) {
                result['keyword'] = splitted_url[1][search_engine['keyword_key']];
            }

            result['keyword'] = sanitize(result['keyword']);
            result['queries'] = splitted_url[1];

            return result;
        }
    }

    return default_search_data();
}

function default_search_data() {
    return {
        'search_label': '',
        'page_kind': 'unknown_page',    // 基本的に未知のページとみなす。
        'keyword': '',
        'result_item_index': '',
        'queries': {}
    };
}

function modifier_keys(event) {
    return {
        'alt'   : event.altKey,
        'ctrl'  : event.ctrlKey,
        'shift' : event.shiftKey,
        'meta'  : event.metaKey,
    }
}

// アクティブなタブのQTH管理用IDを取得する。
// もしまだIDが降られていなければ振って、付帯データストアを初期化する。
function get_current_tab_id(tab) {
    const windowManagerID = '@mozilla.org/appshell/window-mediator;1';
    const windowManagerIF = Components.interfaces.nsIWindowMediator;
    const windowManager   = Components.classes[windowManagerID].getService(windowManagerIF);

    var target_window  = windowManager.getMostRecentWindow('navigator:browser');
    return get_tab_id(target_window.getBrowser().selectedTab);
}

function get_most_recent_browser() {
    const windowManagerID = '@mozilla.org/appshell/window-mediator;1';
    const windowManagerIF = Components.interfaces.nsIWindowMediator;
    const windowManager   = Components.classes[windowManagerID].getService(windowManagerIF);
    var target_window  = windowManager.getMostRecentWindow('navigator:browser');
    return target_window.getBrowser(); 
}

function get_tab_id(tab) {
    // タブからIDを取ってみる
    var tab_id = session_get(tab, 'qth_tab_id');
    if(!tab_id || !(tab_id in get_globals().tabs)) {
        // タブにセッションIDがない == 新規セッション
        // 新しいidを取得
        //tab_id = get_globals().tab_count++;
        tab_id = tab.linkedPanel;

        // タブにidを関連付け
        session_set(tab, 'qth_tab_id', tab_id);

        // タブに対応するデータ辞書を初期化
        get_globals().tabs[tab_id] = init_tab_data(tab_id);
    }
    return tab_id;
}

function init_tab_data(tab_id) {
    var tab_data = {};

    // セッションの開始時間を記録
    tab_data.created = date_time_get_epoch();

    // ページ番号を初期化
    tab_data.page_count = 0;
    tab_data.url2page_id = {};
    
    // セッションのURLも初期化
    tab_data.pre_url = '';

    return tab_data;
}

function get_current_tab_data() {
    return get_tab_data(get_current_tab_id());
}

function get_tab_data(tab_id) {
    if(!get_globals().tabs[tab_id]) get_globals().tabs[tab_id] = init_tab_data(tab_id); 
    return get_globals().tabs[tab_id];
}

// URLに対応するページIDを返す。
function get_page_id(tab_data, current_url, doc) {
    // すでに開いたことのあるページならそのページのIDを返す。
    if(current_url in tab_data.url2page_id) {
        return tab_data.url2page_id[current_url];
    }

    // 新しいページなので、ページIDを振りあて
    tab_data.url2page_id[current_url] = ++tab_data.page_count;
    
    if(dom_get('LogTB-Pause-Button').getAttribute('collapsed')) {
        return tab_data.url2page_id[current_url];
    }

    if(!doc) {
        return tab_data.url2page_id[current_url];
    }

    // ページを保存する (settings -> Cache page が チェックされていた場合のみ)
    if(get_globals().cache_enabled == null) {
        get_globals().cache_enabled = config_get('extension.qth_toolbar.cache_enabled');
    }  

    if(get_globals().cache_enabled) {
        var date_format = '%(year)04d-%(month)02d-%(date)02d_%(hour)02d-%(min)02d-%(sec)02d-%(msec)04d';
        var current_date_str = string_format(date_format, date_time_get_now_dict());
        var base_name = current_date_str + '.' + tab_data.url2page_id[current_url];
        var dst_ifile = path_cd(path_get_profile_dir(), 'QT', 'archive', 'data', base_name +'.html');
        path_enable(dst_ifile);

        var dst_folder_ifile = path_cd(path_get_profile_dir(), 'QT', 'archive', 'data', base_name);
        var persist = makeWebBrowserPersist();
        const nsIWBP = Components.interfaces.nsIWebBrowserPersist;
        var persist_flags = 0;
        persist_flags |=  nsIWBP.PERSIST_FLAGS_FROM_CACHE;
        persist_flags |=  nsIWBP.PERSIST_FLAGS_REPLACE_EXISTING_FILES;
        persist_flags |=  nsIWBP.PERSIST_FLAGS_AUTODETECT_APPLY_CONVERSION;
        persist.persistFlags = persist_flags;
        persist.saveDocument(doc, dst_ifile, dst_folder_ifile, 'text/html', Components.interfaces.nsIWebBrowserPersist.ENCODE_FLAGS_ENCODE_BASIC_ENTITIES, 80);
    }

    return tab_data.url2page_id[current_url];
}

// 実際に文字列を生成してログファイルに書き込む
function append_log(log) {
    if(!log) {
        return;
    }
    if(dom_get('LogTB-Pause-Button').getAttribute('collapsed')) {
        return;
    }

    // ログファイルに書き込み
    var log_format = '%(date_str)s\t%(session_time)s\t%(tab_id)s\t%(page_id)s\t%(event_label)s\t%(search_label)s\t%(keyword)s\t%(anchor_text)s\t%(next_url)s\t%(bookmark_title)s\t%(source_name)s\t%(submit_options)s\t%(submit_action_url)s\t%(next_page_id)s\t%(url)s\t%(title)s\t%(page_kind)s\t%(result_item_index)s\n';

    var log_text_src = string_format(log_format, log);
    var log_text = string_encode(log_text_src, null, 'UTF-8');

    // QTH用のログファイルを用意
    var log_ifile = path_cd(path_get_profile_dir(), 'QT', 'qth_toolbar_log');
    path_enable(log_ifile);

    // 追記
    ifile_append(log_ifile, log_text);
    
    // ステータスダイアログを更新
    if(append_log.is_show_cue) {
        window.openDialog('chrome://qthtoolbar/content/status.xul', 'qth_status', 'width=300,height=100,chrome', log, debug_log);
    }
    if('cue' == log['event_label']) {
        append_log.is_show_cue = true;
        var wnd = window.openDialog('chrome://qthtoolbar/content/status.xul', 'qth_status', 'width=300,height=100,chrome', append_log.pre_log, debug_log);
        setTimeout(function(){
                append_log.is_show_cue = false;
                wnd.close();
            }, 1000 * 10
        );
    }
    append_log.pre_log = log;
}

// 201008開発のログを残す
append_log2 = function (log, tab_id, doc, dum) {

    if(!log) return;

    if(append_log2.force_logging == undefined){
        append_log2.force_logging = false;
    }

    if(dum != undefined) {
        append_log2.force_logging = dum;
    }

    if(dom_get('LogTB-Pause-Button').getAttribute('collapsed') && !append_log2.force_logging) {
        return;
    }

    tab_id = tab_id || get_current_tab_id();

    // そのIDに紐づいたデータ辞書を取得
    var tab_data = get_tab_data(tab_id);

    // documentを更新
    tab_data.doc = doc = (doc || tab_data.doc || get_most_recent_browser().contentDocument);

    if(!doc.location) {
        if(get_most_recent_browser().contentDocument.location) {
            tab_data.doc = doc = get_most_recent_browser().contentDocument;
        } else {
            return;
        }
    }
    tab_id2document[tab_id] = doc;

    // アクティブなタブのIDを取得
    log['tab_id'] = tab_id;

    log['timestamp'] = date_time_get_epoch(); 
    log['title'] = doc.title;
    log['url']   = doc.location.href;

    // ログファイルに書き込み
    var str = [JSON.stringify(log), "\n"].join("");
    var log_text = string_encode(str, null, 'UTF-8');

    // QTH用のログファイルを用意
    var log_ifile = path_cd(qth_LOG_FILE2());
    path_enable(log_ifile);

    // 追記
    ifile_append(log_ifile, log_text);

    append_log2.pre_log = log;

    // 強制ログ取得は、1回きり有効とする
    append_log2.force_logging = false;
}

event_observe(window, 'unload',
    function(event) {
        // window の unload はタブがいくつあっても1回のみ
        var linked_panel = event.originalTarget.defaultView.getBrowser().selectedTab.linkedPanel;
        append_log2({'event_label': 'unload'}, linked_panel);

        // ウインドウ内のタブのcloseイベントを記録
        for(var tab_id in tab_id2document) {
            append_log(build_log({'event_label': 'close'}, tab_id2document[tab_id], tab_id));
        }

        // これが最後のウインドウならendイベントを記録
        get_globals().window_count -= 1;
        if(0 == get_globals().window_count) {
            append_log(build_log({'event_label': 'end'}));
        }
    }
)

// 以降QTH独自のイベントを得るための処理
// まずウインドウの初期化終了時にアタッチ
event_observe(window, 'load',
    function(event) {
        try {
            var target_browser = event.originalTarget.defaultView.getBrowser();
            var shistoryListener = function(linked_panel) {
                return {
                    QueryInterface: function(iid) {
                        if (iid.equals(Components.interfaces.nsISHistoryListener) ||
                            iid.equals(Components.interfaces.nsISupportsWeakReference) ||
                            iid.equals(Components.interfaces.nsISupports)) {
                                return this;
                            }
                            throw Components.results.NS_ERROR_NO_INTERFACE;
                        },
                    GetWeakReference: function() {
                        return Components.classes["@mozilla.org/appshell/appShellService;1"]
                          .createInstance(Components.interfaces.nsIWeakReference);
                    },
                    OnHistoryGoBack: function(uri) {
                        append_log2({'eventType':'OnHistoryGoBack'}, this.linkedPanel);
                        return true; // go on
                    },
                    OnHistoryGoForward: function(uri) {
                        append_log2({'eventType':'OnHistoryGoForward'}, this.linkedPanel);
                        return true;
                    },
                    OnHistoryGotoIndex: function(index, uri) {
                        var tab_data = get_tab_data(this.linkedPanel);
                        append_log2({
                            'eventType':'OnHistoryGotoIndex',
                            'history_index_before': tab_data['currentIndex'], 
                            'history_index_after': index
                        }, this.linkedPanel);
                        return true;
                    },
                    OnHistoryNewEntry: function(uri) {
                        append_log2({'eventType':'OnHistoryNewEntry'}, this.linkedPanel);
                    },
                    OnHistoryPurge: function(uri) {
                        return true;
                    },
                    OnHistoryReload: function(uri) {
                        append_log2({'eventType':'OnHistoryReload'}, this.linkedPanel);
                        return true;
                    },
                    linkedPanel : linked_panel,
                }
            };

            var attachSHistoryCaptor = function(targetWindow, linked_panel) {
                var nsISHistory = targetWindow.webNavigation.sessionHistory;
                if(nsISHistory) {
                    try {
                        var tab_data = get_tab_data(linked_panel);
                        if(! tab_data.shistoryListener) {
                            tab_data.shistoryListener = shistoryListener(linked_panel);
                        }
                        nsISHistory.addSHistoryListener(tab_data.shistoryListener);
                        tab_data['currentIndex'] = nsISHistory.index;
                    } catch(E) {
                        debug_log(E);
                    }
                } else {
                    debug_log("FAILURE: history captor attached");
                }
            }


            target_browser.addTabsProgressListener({
                QueryInterface: function(iid) {
                        if (iid.equals(Components.interfaces.nsIWebProgressListener)) {
                              return this;
                        }
                        throw Components.results.NS_ERROR_NO_INTERFACE;
                },
                onStateChange: function(browser) {
                },
                onProgressChange: function(browser) {
                },
                onLocationChange: function(browser, webProgress, request, location) {
                    var linked_panel = null;
                    var targetBrowserIndex = -1;
                    try {
                        if(request) {
                            var httpChannel = request.QueryInterface(Components.interfaces.nsIHttpChannel);
                            var interfaceRequestor = null;
                            if(httpChannel.notificationCallbacks) {
                                interfaceRequestor = httpChannel.notificationCallbacks.QueryInterface(Components.interfaces.nsIInterfaceRequestor); 
                            } else {
                                notificationCallbacks = request.loadGroup.notificationCallbacks;
                                interfaceRequestor = notificationCallbacks.QueryInterface(Components.interfaces.nsIInterfaceRequestor); 
                            }
                            var targetDoc = interfaceRequestor.getInterface(Components.interfaces.nsIDOMWindow).document;
                            targetBrowserIndex = gBrowser.getBrowserIndexForDocument(targetDoc);
                        } else {
                            targetBrowserIndex = gBrowser.getBrowserIndexForDocument(browser.contentDocument);
                        }

                        if (targetBrowserIndex != -1) {
                            linked_panel = gBrowser.tabContainer.childNodes[targetBrowserIndex].linkedPanel;
                        } 
                    } catch (err) {
                        debug_log(err)
                    }
                    append_log2({'eventType':'onLocationChange', 'url': location.asciiSpec}, linked_panel)

                    var tab_data = get_tab_data(linked_panel);
                    setTimeout(function(){attachSHistoryCaptor(browser, linked_panel)});
                },
                onStatusChange: function() {
                },
                onSecurityChange: function() {
                },
            });
        } catch(err) {
            debug_log(err);
        }

        tab_id2document[get_current_tab_id()] = document

        // ウインドウの数を数える
        get_globals().window_count += 1;
        
        // 次にウインドウ内のページが読み込まれたときのイベントにアタッチ
        // link用
        attach_on_content_loaded()

        // startイベントの記録
        event_observe(dom_get('LogTB-Start-Button'), 'click', 
            function(){
                // ボタンが押された直後はまだPauseボタンが無効で、ログが記録されないので、遅延して記録させる
                setTimeout(
                    function(){
                        append_log(build_log({'event_label': 'start'}));
                    }
                );
            }
        )

        event_observe(dom_get('FindToolbar')._findField, 'focus',
            function() {
                append_log(build_log({'event_label': 'focus'}));
            }
        )

        // 進むボタン・戻るボタンにもアタッチ
        // next, return用
        var orig_BrowserBack = BrowserBack;
        BrowserBack = function(aEvent) {
            var log = {
                'event_label': 'return'
            };

            var where = whereToOpenLink(aEvent, false, true);

            if (where == "current") {
                try {
                    log['next_url'] = gBrowser.contentWindow.history.previous;
                }
                catch(ex) {
                }
            }
            else {
                var sessionHistory = getWebNavigation().sessionHistory;
                var currentIndex = sessionHistory.index;
                var entry = sessionHistory.getEntryAtIndex(currentIndex - 1, false);
                var url = entry.URI.spec;
                log['next_url'] = url;
            }

            var tab_data = get_current_tab_data();
            log['next_page_id'] = get_page_id(tab_data, log['next_url']);
            append_log(build_log(log));
            orig_BrowserBack(aEvent);
        }

        var orig_BrowserForward = BrowserForward;
        BrowserForward = function(aEvent) {
            var log = {
                'event_label': 'next'
            };

            var where = whereToOpenLink(aEvent, false, true);

            if (where == "current") {
                try {
                    log['next_url'] = gBrowser.contentWindow.history.next;
                } catch(ex) {
                }
            }
            else {
                var sessionHistory = getWebNavigation().sessionHistory;
                var currentIndex = sessionHistory.index;
                var entry = sessionHistory.getEntryAtIndex(currentIndex + 1, false);
                var url = entry.URI.spec;
                log['next_url'] = url;
            }

            var tab_data = get_current_tab_data();
            log['next_page_id'] = get_page_id(tab_data, log['next_url']);
            append_log(build_log(log));
            orig_BrowserForward(aEvent);
        }

        gURLBar._copyCutController.orig_doCommand = gURLBar._copyCutController.doCommand;
        gURLBar._copyCutController.doCommand = function(command) {
            if(command.match('cmd_copy')) {
                append_log(build_log({'event_label': 'copy'}));
                append_log2({'eventType': 'doCommand', 'cmd': command, 'clipboard_toString': gURLBar.inputField.value});
            }
            if(command.match('cmd_cut')) {
                append_log(build_log({'event_label': 'cut'}));
                append_log2({'eventType': 'doCommand', 'cmd': command, 'clipboard_toString': gURLBar.inputField.value});
            }
            gURLBar._copyCutController.orig_doCommand(command)
        }

        event_observe(gURLBar.inputField, 'paste', function(){
            append_log(build_log({'event_label': 'paste'}));
            setTimeout(function(){append_log2({'eventType': 'paste', 'clipboard_toString': gURLBar.inputField.value})});
        });

        event_observe(gURLBar.inputField, 'focus',
            function() {
                append_log(build_log({'event_label': 'focus'}));
            }
        )

        event_observe(BrowserSearch.searchBar.textbox, 'copy', function(){
            append_log(build_log({'event_label': 'copy'}));
        });

        event_observe(BrowserSearch.searchBar.textbox, 'cut', function(){
            append_log(build_log({'event_label': 'cut'}));
        });

        event_observe(BrowserSearch.searchBar.textbox, 'paste', function(){
            append_log(build_log({'event_label': 'paste'}));
        });

        var orig_goDoCommand = goDoCommand;
        goDoCommand = function(command) {
            if(command.match('cmd_copy.+')) {
                append_log(build_log({'event_label': 'copy'}));
            }
            if(command.match('cmd_cut.*')) {
                append_log(build_log({'event_label': 'cut'}));
            }
            orig_goDoCommand(command)
        }
        event_observe(dom_get('contentAreaContextMenu'), 'popupshown',
            function(event){
                if(!gContextMenu.orig_copyMediaLocation) {
                    gContextMenu.orig_copyMediaLocation = gContextMenu.copyMediaLocation;
                    gContextMenu.copyMediaLocation = function() {
                        append_log(build_log({'event_label': 'copy'}));
                        gContextMenu.orig_copyMediaLocation();
                    }

                    gContextMenu.orig_copyEmail = gContextMenu.copyEmail;
                    gContextMenu.copyEmail = function() {
                        append_log(build_log({'event_label': 'copy'}));
                        gContextMenu.orig_copyEmail();
                    }
                }
            }
        );


        event_observe(dom_get('bookmarksMenu'), 'DOMNodeInserted',
            function(event){
                event_observe(event.target, 'command',
                    function() {
                        if(event.target.className == 'menuitem-iconic bookmark-item') {
                            get_globals().on_jump = true;
                        }
                    }
                );
            }
        );
        event_observe(window, 'dragdrop',
            function(event){
                get_globals().on_jump = true;
            }
        );
        event_observe(dom_get('bookmarksBarContent'), 'DOMNodeInserted',
            function(event){
                event_observe(event.target, 'command',
                    function() {
                        if(event.target.className == 'menuitem-iconic bookmark-item') {
                            get_globals().on_jump = true;
                        }
                        if(event.target.className == 'bookmark-item') {
                            get_globals().on_jump = true;
                        }
                    }
                );
            }
        );
        array_each(dom_get('bookmarksBarContent').getElementsByTagName('toolbarbutton'),
            function(toolbarbutton) {
                event_observe(toolbarbutton, 'command',
                    function(){
                        if(toolbarbutton.className == 'bookmark-item') {
                            get_globals().on_jump = true;
                        }
                    }
                );
            }
        );

        event_observe(dom_get('back-forward-dropmarker'), 'DOMNodeInserted',
            function(event){
                event_observe(event.target, 'command',
                    function() {
                        get_globals().on_jump = true;
                    }
                );
            }
        );
        event_observe(dom_get('history-menu'), 'DOMNodeInserted',
            function(event){
                event_observe(event.target, 'command',
                    function() {
                        if(event.target.className == 'menuitem-iconic bookmark-item') {
                            get_globals().on_jump = true;
                        }
                    }
                );
            }
        );

        // log をブラウザ上で閲覧
        event_observe(dom_get('qth_view_log'), 'click',
            function() {
                var log_ifile = path_cd(path_get_profile_dir(), 'QT', 'qth_toolbar_log');
                loadURI(log_ifile.path)
            }
        );

        // log2 をブラウザ上で閲覧
        event_observe(dom_get('qth_view_log2'), 'click',
            function() {
                loadURI(qth_LOG_FILE2().path)
            }
        );

        // 検索イベントの取得
        gFindBar.orig_onFindAgainCommand = gFindBar.onFindAgainCommand;
        gFindBar.onFindAgainCommand = function(afindPrevious) {
            gFindBar.orig_onFindAgainCommand(afindPrevious);
            append_log(build_log({'event_label': 'find_again', 'keyword': gFindBar._findField.value}));
            append_log2({'eventType':'onFindAgainCommand', 'find_text':gFindBar._findField.value});
        }

        event_observe(dom_get('editBookmarkPanelDoneButton'), 'click',
            function(){
                var log = build_log({'event_label': 'bookmark'});
                log['bookmark_title'] = log['title']
                append_log(log);
            }
        )
        event_observe(dom_get('go-button'), 'click', function(){
                get_globals().on_jump = true;
            }
        )
        event_observe(dom_get('urlbar'), 'keypress', function(event){
                if(13 == event.keyCode)
                    get_globals().on_jump = true;
            }
        )
        
        var show_cue_button = dom_create('toolbarbutton', {'label': 'Show Cue'});
        dom_insert_after(dom_get('LogTB-Toolbar').childNodes[0], show_cue_button);
        event_observe(show_cue_button, 'command',
            function(){
                append_log(build_log({'event_label': 'cue'}));
            }
        );
        
        event_observe(dom_get('bookmarksMenu'), 'popupshowing',
            function(){
                append_log(build_log({'event_label': 'focus'}));
            }
        );

        qth_Clear_Log = function (event) {
            qth_remove_files(event, "log", qth_LOG_FILE(), false);
        };

        qth_Clear_Log2 = function (event) {
            qth_remove_files(event, "log", qth_LOG_FILE2(), false);
        };

        qth_Clear_Cache = function (event) {
            qth_remove_files(event, "cache", qth_CACHE_DIR(), true);
        };

        qth_Upload_Log = function(event) {
            var serverUrl = config_get('extension.qth_toolbar.server');

            if(serverUrl == null || serverUrl == '') {
                return;
            }

            var srcFile = qth_LOG_FILE();
            if(srcFile == null) {
                return;
            }

            var txt = ifile_readText(srcFile);
            var headers = new Array();
            headers['Content-Type'] = 'application/octet-stream';
            http_get(serverUrl,
                function(responseTxt, req) {
                    if(req.status == 200) {
                        alert('Uploaded successfully');
                    } else {
                        alert('Failed. Check URL, or server may be down?');
                    }
                }, 
                txt, headers
            );
        };

        qth_Upload_Log2 = function(event) {
            var serverUrl = config_get('extension.qth_toolbar.server');

            if(serverUrl == null || serverUrl == '') {
                return;
            }

            var srcFile = qth_LOG_FILE2();
            if(srcFile == null) {
                return;
            }

            var txt = ifile_readText(srcFile);
            var headers = {};
            headers['Content-Type'] = 'application/octet-stream';
            http_get(serverUrl,
                function(responseTxt, req) {
                    if(req.status == 200) {
                        alert('Uploaded successfully');
                    } else {
                        alert('Failed. Check URL, or server may be down?');
                    }
                }, 
                txt, headers
            );
        };
    }
)

function get_tab_from_event(event) {
    // 新しく開かれたタブのURLをとる。
    var url = event.target.location.href;
    if(event.originalTarget && event.originalTarget.location)
        url = event.originalTarget.location.href;

    // すべてのタブのURLと、対応するタブのIDの辞書を作る
    var ff_tab_id = null;
    for(var index = gBrowser.browsers.length - 1; 0 <= index; --index) {
        var browser = gBrowser.getBrowserAtIndex(index);
        if(url != browser.currentURI.spec)
            continue;
        ff_tab_id = browser.parentNode.getAttribute('id');
        break;
    }

    // 新しく開かれたタブのURLに対応するタブIDから、タブのインスタンスを得る
    return get_tab_id_from_panel_id(ff_tab_id);
}

function get_tab_id_from_panel_id(panel_id) {
    // 新しく開かれたタブのURLに対応するタブIDから、タブのインスタンスを得る
    var tab_container = gBrowser.selectedTab.parentNode.childNodes;
    for(var index = tab_container.length - 1; 0 <= index; --index) {
        if(panel_id != tab_container[index].getAttribute('linkedPanel')) {
            continue;
        }
        return tab_container[index];
    }
    return null;
}

// タブを閉じるイベントにアタッチ
event_observe(gBrowser.tabContainer, 'TabClose',
    function(event){
        var linked_panel = event.target.linkedPanel;
        var target_document = event.target.linkedBrowser.contentDocument;
        delete tab_id2document[linked_panel];
        append_log(build_log({'event_label': 'close'}, target_document, linked_panel));
        append_log2({'eventType': event.type}, linked_panel, target_document);
    }
)

event_observe(gBrowser.tabContainer, 'TabOpen',
    function(event){
        var linked_panel = event.target.linkedPanel;
        var target_document = event.target.linkedBrowser.contentDocument;
        tab_id2document[linked_panel] = target_document;
        append_log(build_log({'event_label': 'open'}, target_document, tab_id));
        append_log2({'eventType': event.type}, linked_panel, target_document);
    }
)



// 各ページの読み込み完了時のハンドラ。
// すべてのAタグにアタッチしてlinkイベントを取る。
function attach_on_content_loaded() {
    event_observe(dom_get('appcontent'), 'DOMContentLoaded',
        function(event){
            // 読み込まれたページのdocumentを取得
            var doc = event.target.defaultView.document;
            var tab = gBrowser.mTabs[gBrowser.getBrowserIndexForDocument(event.originalTarget)];
            var linked_panel = tab.linkedPanel;

            if(!tab) {
                return;
            }

            var qth_tab_id = linked_panel;
            append_log(build_log({'event_label': 'load'}, doc, qth_tab_id));
            append_log2({'eventType': 'DOMContentLoaded'}, linked_panel);
        },
        true
    )

    // ウインドウ内のページが読み込まれたときのイベントにアタッチ
    event_observe(dom_get('appcontent'), 'pagehide',
        function(event) {
            var doc = event.originalTarget.defaultView.document;
            var linked_panel = get_most_recent_browser().mTabs[get_most_recent_browser().getBrowserIndexForDocument(event.originalTarget)].linkedPanel;
            append_log2({'eventType' : event.type}, linked_panel, doc);
        }
    )

    event_observe(dom_get('appcontent'), 'pageshow',
        function(event) {
            // 読み込まれたページのdocumentを取得
            var doc = event.target.defaultView.document;
            var linked_panel = get_most_recent_browser().mTabs[get_most_recent_browser().getBrowserIndexForDocument(event.originalTarget)].linkedPanel;

            var qth_tab_id = linked_panel;

            if(--w_add_tab_count < 0) {
                w_add_tab_count = 0;    // throw 'Unreachable';
            }

            if(get_globals().on_jump) {
                get_globals().on_jump = false;
                append_log(build_log({'event_label': 'jump'}, doc, qth_tab_id));
            }

            append_log(build_log({'event_label': 'show'}, doc, qth_tab_id));

            append_log2({
              'eventType'  : 'pageshow',
              'pageshow_url' : doc.location['href'],
            }, linked_panel);

            event_observe(doc.body, 'copy',
                function(){
                    append_log(build_log({'event_label': 'copy'}, doc, qth_tab_id));
                }
            )
            
            event_observe(doc.body, 'cut',
                function(){
                    append_log(build_log({'event_label': 'copy'}, doc, qth_tab_id));
                }
            )
            
            array_each(doc.getElementsByTagName('INPUT'),
                function(tag) {
                    event_observe(tag, 'paste',
                        function(event) {
                            append_log(build_log({'event_label': 'paste'}), doc, qth_tab_id);
                        }
                    )
                }
            )

            array_each(doc.getElementsByTagName('TEXTAREA'),
                function(tag) {
                    event_observe(tag, 'paste',
                        function(event) {
                            append_log(build_log({'event_label': 'paste'}), doc, qth_tab_id);
                        }
                    )
                }
            )

            var detect_a_tag = function(event) {
                var target_node = event.target;
                while(true) {
                    if(target_node.tagName == 'A') return target_node;
                    target_node = target_node.parentNode;
                }
            }
            
            // link のログをとる
            var log_link = function(event){
                try {
                var target_node = detect_a_tag(event);
                var tab_data = get_tab_data(qth_tab_id);

                var target_node_outerHTML = '';
                try {
                    var doc = target_node;
                    while(true) {
                        if(doc instanceof HTMLDocument) {
                            break;
                        }
                        doc = doc.parentNode;
                        if(doc == null) {
                            break;
                        }
                    }

                    target_node_outerHTML = doc.createElement('div').
                        appendChild(target_node.cloneNode(true)).parentNode.innerHTML;
                } catch (e) {
                    debug_log(e);
                }

            
                var log = {
                    'eventType' : event.type,
                    'button'     : event.button,
                    'key_code'   : event.keyCode,
                    'event_label': 'link',
                    'anchor_html': sanitize(target_node_outerHTML),
                    'next_url'   : target_node.getAttribute('href'),
                    'anchor_text': sanitize(event.target.textContent),
                };
            
                if(event.type == 'keydown'){
                    log['key_code']  = event.keyCode;
                    log['alt_key']   = event.altKey;
                    log['ctrl_key']  = event.ctrlKey;
                    log['shift_key'] = event.shiftKey;
                    log['meta_key']  = event.metaKey;
                } else {
                    log['button'] = event.button;
                }
                
                if(null == log['next_url']){
                    log['next_url'] = '(href not found)'
                } else {
                    log['next_url'] = url_rel_to_abs(doc, log['next_url'])
                    log['next_page_id'] = get_page_id(tab_data, log['next_url']);
                }
            
                if(event.target.hasAttribute('name')) {
                    log['source_name'] = event.target.getAttribute('name');
                }
                } catch (e) {
                    debug_log(e);
                }

                append_log(build_log(log), doc, qth_tab_id);
            }

            // linkイベントのためにaタグのclickイベントにアタッチ
            //var a_tags = doc.getElementsByTagName('A');
            array_each(window.content.document.links,
                function(a_tag) {

                    // keydown のとき、 Enter のみ取得
                    event_observe(a_tag, 'keydown',
                        function(event) {
                            if(event.keyCode == 13) {
                                log_link(event);
                            }
                        }
                    );

                    // click のとき、button なし のみ取得 ←???
                    event_observe(a_tag, 'click',
                        function(event) {
                            if(event.button == null) {
                                log_link(event);
                            }
                        }
                    );

                    // mousedown したら、mouseup で click と認識するイベントをattach
                    event_observe(a_tag, 'mousedown',
                        function(event){
                            if(event.button == 2) return; // 右クリックは無視
                            get_globals().mousedown_target = event.target;

                            event_observe(event.target, 'dragenter', 
                                function(e){
                                    get_globals().mousedown_target = null;
                                }
                            );

                            event_observe(event.target, 'mouseout', 
                                function(e){
                                    get_globals().mousedown_target = null;
                                }
                            );
                        }
                    );

                    event_observe(a_tag, 'mouseup',
                        function(event){
                            if(event.button == 2) return; // 右クリックは無視
                            if(event.target == get_globals().mousedown_target) {
                                log_link(event);
                            }
                        }
                    );

                }
            );

            var form_tags = doc.getElementsByTagName('FORM');
            array_each(form_tags,
                function(form_tag) {
                    event_observe(form_tag, 'submit',
                        function(event) {
                            var log = {
                                'event_label': 'submit',
                                'submit_action_url': event.target.getAttribute('action'),
                                'method': event.target.getAttribute('method')
                            };

                            if(null == log['submit_action_url'])
                                log['submit_action_url'] = '(action not found)'
                            else {
                                log['submit_action_url'] = url_rel_to_abs(doc, log['submit_action_url'])
                                var tab_data = get_tab_data(qth_tab_id);
                                log['next_page_id'] = get_page_id(tab_data, log['submit_action_url']);
                            }

                            if(event.target.hasAttribute('id')) {
                                log['source_name'] = event.target.getAttribute('id');
                            } else if(event.target.hasAttribute('name')) {
                                log['source_name'] = event.target.getAttribute('name');
                            }

                            get_globals().on_submit = log;
                        }
                    )
                }
            )

            // 検索結果ならsearch/browseイベントをログ
            var url = doc.location.href;
            var search_data = extract_search_data(url, doc);
            if('search_result_page' == search_data['page_kind']) {
                // 検索結果。search/browseイベント発生。

                // 今検索中で、前回とサーチエンジンとキーワードが同じならbrowse
                function get_type(){
                    var pre_search_data = get_globals().pre_search_data;
                    var search_data_keys = [];
                    for(var key in search_data['queries']) {
                        search_data_keys.push(key);
                    }
                    var pre_search_data_keys = [];
                    for(var key in pre_search_data['queries']) {
                        pre_search_data_keys.push(key);
                    }
                    if(search_data_keys.length != pre_search_data_keys.length) {
                        return 'search';
                    }
                    
                    for(var i = 0; i < search_data_keys.length; i++) {
                        if(search_data['index_key'] == search_data_keys[i]) {
                            continue;
                        }
                        if(search_data_keys[search_data_keys[i]] != pre_search_data_keys[search_data_keys[i]]) {
                            return 'search';
                        }
                    }
                    return 'browse';
                }
                append_log(build_log({'event_label': get_type()}), doc, qth_tab_id);
            }
            // 検索に関するデータを保存
            get_globals().pre_search_data = search_data;
        }
    )
}

////////////////////////////////
// branch
////////////////////////////////

///////////////////////////////////////////////////////////////////////
// Remove files
///////////////////////////////////////////////////////////////////////
function qth_remove_files(event, filetypeLabel, path, recursive) {
    var result = confirm("Clear "+ filetypeLabel + " files?");
    if(!result) {
        return;
    }
    path.remove(recursive);
}

function qth_LOG_FILE() {
    return path_cd(path_get_profile_dir(), 'QT', 'qth_toolbar_log');
}

function qth_LOG_FILE2() {
    return path_cd(path_get_profile_dir(), 'QT', 'qth_toolbar_log2');
}

function qth_CACHE_DIR() {
    return path_cd(path_get_profile_dir(), 'QT', 'archive', 'data');
}

function ifile_readText(ifile) {
    var istream = Components.classes["@mozilla.org/network/file-input-stream;1"]
        .createInstance(Components.interfaces.nsIFileInputStream);
    istream.init(ifile, -1, -1, false);

    var bstream = Components.classes["@mozilla.org/binaryinputstream;1"]
        .createInstance(Components.interfaces.nsIBinaryInputStream);
    bstream.setInputStream(istream);

    var bytes = bstream.readBytes(bstream.available());

    return bytes;
}

////////////////////////////////


////////////////////////////////
// 生リクエスト情報を記録する
////////////////////////////////
var httpRequestObserver = {
    observe: function(subject, topic, data) {
        if (topic == "http-on-modify-request") {
            var httpChannel = subject.QueryInterface(Components.interfaces.nsIHttpChannel);
            var notificationCallbacks = null;
            if(httpChannel.notificationCallbacks) {
                notificationCallbacks = httpChannel.notificationCallbacks;
            } else {
                notificationCallbacks = subject.loadGroup.notificationCallbacks;
            }
                
            if(!notificationCallbacks) {
                return;
            }

            var interfaceRequestor = notificationCallbacks.QueryInterface(Components.interfaces.nsIInterfaceRequestor); 

            // ヘッダ情報を読み出す
            var aVisitor = {
                headers : {},
                visitHeader : function ( aHeader, aValue ) {  
                    this.headers[aHeader] = aValue;
                }
            };
            subject.visitRequestHeaders(aVisitor);

            var headers = [];
            for(key in aVisitor.headers){
                headers.push([key, aVisitor.headers[key]].join(':'));
            }

            // XMLHttpRequest
            var linked_panel = null;
            {
                try {
                    var targetDoc = interfaceRequestor.getInterface(Components.interfaces.nsIDOMDocument);
                    var targetBrowserIndex = gBrowser.getBrowserIndexForDocument(targetDoc);

                    // handle the case where there was no tab associated with the request (rss, etc)
                    if (targetBrowserIndex != -1) {
                        linked_panel = gBrowser.tabContainer.childNodes[targetBrowserIndex].linkedPanel;
                    } 
                } catch (err) {
                    debug_log(err);
                }
            }

            append_log2({
                    'eventType'  : 'http_req',
                        'requestURI' : httpChannel.URI.spec,
                        'method'     : httpChannel.requestMethod,
                        'http_req'   : headers.join("\n")
                        },  linked_panel);
        }
    },

    get observerService() {
        return Components.classes["@mozilla.org/observer-service;1"]
               .getService(Components.interfaces.nsIObserverService);
    },

    register: function() {
        this.observerService.addObserver(this, "http-on-modify-request", false);
    },

    unregister: function() {
        this.observerService.removeObserver(this, "http-on-modify-request");
    }
};
httpRequestObserver.register();

var _privateBrowserListener = new PrivateBrowsingListener();  
_privateBrowserListener.watcher = {
    onEnterPrivateBrowsing : function() {  
        append_log2.force_logging = true;
        append_log2({'eventType':'onEnterPrivateBrowsing'}); 
    },  
     
    onExitPrivateBrowsing : function() {  
        var qth_globals = xpcom_get('@kyagroup.com/qth_toolbar/singleton_object;1');
        qth_globals.is_initialized = false
        currentBrowserInitialized = false;
        var f = append_log2;
        f.force_logging = true;
        f({'eventType':'onExitPrivateBrowsing'}, null, null, f.force_logging); 
    }  
};  

////////////////////////////////////////////////////////////////////////////////

if (searchbar) {
    searchbar.handleSearchCommand_original = searchbar.handleSearchCommand;
    searchbar.handleSearchCommand = function(aEvent) {
        this.handleSearchCommand_original(aEvent);

        append_log2({
          'eventType'                     : 'handleSearchCommand',
          'handleSearchCommand_eventType' : aEvent.type,
          'search_text'                   : aEvent.originalTarget.value
        });
    };   
}

////////////////////////////////////////////////////////////////////////////////

})()