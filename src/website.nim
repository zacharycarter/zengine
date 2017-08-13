import vdom, karax, karaxdsl
proc createDom(): VNode =
  result = buildHtml(tdiv(class="todomvc-wrapper"))

setRenderer createDom