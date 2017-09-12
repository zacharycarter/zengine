ace.require("ace/split");

var editor = ace.edit("editor");
editor.setTheme("ace/theme/monokai");
editor.getSession().setMode("ace/mode/python");
editor.setAutoScrollEditorIntoView(true);
editor.getSession().setUseWrapMode(true);
editor.resize();

var editorEle = document.getElementById("editor")
editorEle.editor = editor;

editorEle.getEditor = function() {
    return this.editor;
}

function getUrlParameter(name) {
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
    var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
    var results = regex.exec(location.search);
    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
};

if(getUrlParameter('code') != "") {
    editorEle.editor.setValue(getUrlParameter('code'), -1);
}

if(getUrlParameter('gist') != "") {
  var request = new XMLHttpRequest();
  request.open('GET', '/gist/' + getUrlParameter('gist'), true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      // Success!
      var resp = request.responseText;
      editorEle.editor.setValue(resp);
    } else {
      // We reached our target server, but it returned an error

    }
  };

  request.onerror = function() {
    // There was a connection error of some sort
  };

  request.send();
}