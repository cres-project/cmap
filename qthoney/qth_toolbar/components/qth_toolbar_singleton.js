////////////////////////////////////////////////////////////////////////////////

function NSGetModule() {
	function xpcom_ns_get_module_impl(conponent_uuid, component_name, conponent_id, create_instance_func) {
		if(!create_instance_func)
			create_instance_func = function(){ return {}; }
		return {
			registerSelf : function (compMgr, fileSpec, location, type) {
				compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar).registerFactoryLocation(
					Components.ID(conponent_uuid),
					component_name,
					conponent_id,
					fileSpec,
					location,
					type
				);
			},
			getClassObject : function() {
				return {
					createInstance : function() {
						var instance = create_instance_func();
						instance.wrappedJSObject = instance;
						return instance;
					}
				};
			},
			canUnload : function() {
				return true;
			}
		}
	}
	return xpcom_ns_get_module_impl('9636088b-c9d9-49e9-9be6-53479e870f34', 'qth_toolbar_singleton_object', '@kyagroup.com/qth_toolbar/singleton_object;1')
}

///////////////////////////////////////////////////////////////////070913.171300
