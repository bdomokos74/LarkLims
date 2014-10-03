@show_order_handler = (event) ->
  event.preventDefault()
  a_clicked = event.toElement
  if a_clicked.nodeName == "SPAN"
    a_clicked = a_clicked.parentNode

  order_url = a_clicked.href

  $.ajax order_url,
    type: 'GET',
    dataType: 'json',
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "AJAX Error: #{textStatus}"
      $("#orders-table").addClass("hidden")
      $("#error-message").removeClass("hidden")

    success: (data, textStatus, jqXHR) ->
      $("#show-order-table li.product-param").remove()

      $("#browser-list-header-tab").addClass("hidden")
      $("#orders-table").addClass("hidden")
      $("#products-table").addClass("hidden")
      $("#users-table").addClass("hidden")
      $("#show-order-table").removeClass("hidden")

      # add product specific params
      $.ajax '/orders/'+data.id+'/product_params',
        type: 'GET',
        async: false,
        dataType: 'json',
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
          $("#show-order-table").addClass("hidden")
          $("#error-message").removeClass("hidden")

        success: (product_params, textStatus, jqXHR) ->
          product_params.reverse()

          for item in product_params
            copied = $("#param-template-txt li").clone()
            newid = "pp-"+item.id
            copied.attr("id", newid)
            copied.insertAfter($("#show-order-table div ul.browser-list li:first"))
            $("#"+newid+" span.param-title").html(item.name)
            if item.value
              $("#"+newid+" span.param-value").html(item.value)
            $("#"+newid+" span:nth-child(2)").attr("id", "orderparam-"+item.key+"-txt")
            $("#"+newid+" span:nth-child(3)").attr("id", "orderparam-"+item.key+"-edit")
            $("#"+newid+" span:nth-child(3) input").attr("id", "orderparam-"+item.key+"-entry")
            $("#"+newid+" span:nth-child(4)").attr("id", "orderparam-"+item.key+"-button")

          $("#show-order-table input.order-id")[0].value = data.id
          $("#order-product-txt").html(data.product_name)
          $("#order-comment-txt").html(data.comment)
          $("#order-ordered_from-txt").html(data.ordered_from)
          $("#order-price-txt").html(data.price)
          $("#order-quantity-txt").html(data.quantity)
          $("#order-units-txt").html(data.units)
          $("#order-department-txt").html(data.department)
          shorturl = data.url
          fullurl = data.url
          if shorturl == null
            shorturl = ""
            fullurl = ""

          maxlen = 45
          if shorturl.length > maxlen
            shorturl = shorturl.substr(0, maxlen)+"..."
          $("#order-url-txt").html("<a target=\"_blank\"></a>")
          $("#order-url-txt a").html(shorturl)
          $("#order-url-txt a").attr("href", fullurl)

show_param_editor = (prefix, param_name) ->
  $(prefix+"-"+param_name+"-txt").addClass("hidden")
  $(prefix+"-"+param_name+"-entry")[0].value = $(prefix+"-"+param_name+"-txt")[0].textContent
  $(prefix+"-"+param_name+"-edit").removeClass("hidden")
  $(prefix+"-"+param_name+"-button div.control-butt").removeClass("hidden")
  $(prefix+"-"+param_name+"-button div.edit-butt").addClass("hidden")

@edit_order_param_handler = (event) ->
  item_clicked = event.toElement
  clicked_id =  item_clicked.parentNode.parentNode.id
  id_split = clicked_id.split('-')
  param_name = id_split[1]
  console.log "editing "+param_name+" "+id_split[0]

  prefix = "#order"
  if id_split[0] == "orderparam"
    prefix = "#orderparam"
  show_param_editor(prefix, param_name)

hide_param_editor = (prefix, param_name) ->
  $(prefix+"-"+param_name+"-txt").removeClass("hidden")
  $(prefix+"-"+param_name+"-edit").addClass("hidden")
  $(prefix+"-"+param_name+"-button div.control-butt").addClass("hidden")
  $(prefix+"-"+param_name+"-button div.edit-butt").removeClass("hidden")

@cancel_order_param_handler = (event) ->
  item_clicked = event.toElement
  clicked_id =  item_clicked.parentNode.parentNode.id
  id_split = clicked_id.split('-')
  param_name = id_split[1]
  console.log "cancelling "+param_name
  prefix = "#order"
  if id_split[0] == "orderparam"
    prefix = "#orderparam"

  hide_param_editor(prefix, param_name)

@save_order_param_handler = (event) ->
  item_clicked = event.toElement
  clicked_id =  item_clicked.parentNode.parentNode.id
  id_split = clicked_id.split('-')
  param_name = id_split[1]
  order_id = $("#show-order-table input.order-id")[0].value

  console.log "saving "+param_name+" "+id_split[0]+" "+order_id

  save_url = "/orders/"+order_id
  param_value = null
  prefix = "#order"
  save_data = null
  params = {}

  if id_split[0]=="orderparam"
    pid_split = item_clicked.parentNode.parentNode.parentNode.id.split("-")
    param_id = pid_split[1]
    save_url = "/orders/"+order_id+"/product_params/"+param_id
    param_value =  $("#orderparam-"+param_name+"-entry")[0].value
    prefix = "#orderparam"

    save_data = {'product_param': {'value': param_value}}
  else
    param_value =  $("#order-"+param_name+"-entry")[0].value
    params[param_name] = param_value
    save_data = { 'order': params}

  $.ajax save_url,
    async: false
    type: 'PATCH'
    data: save_data
    dataType: 'json'
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "PATCH ORDER AJAX Error: #{textStatus}"

    success: (data, textStatus, jqXHR) ->
      console.log "PATHCH ORDER  Successful AJAX call"

      $(prefix+"-"+param_name+"-edit").addClass("hidden")
      $(prefix+"-"+param_name+"-entry")[0].value = ""
      $(prefix+"-"+param_name+"-txt").text(param_value)
      $(prefix+"-"+param_name+"-txt").removeClass("hidden")

      $(prefix+"-"+param_name+"-button div.control-butt").addClass("hidden")
      $(prefix+"-"+param_name+"-button div.edit-butt").removeClass("hidden")
