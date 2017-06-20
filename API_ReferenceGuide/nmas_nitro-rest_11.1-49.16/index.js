rdx.views =
{
    header_view:
    {
        type: rdx.view_constants.HEADER_VIEW,
        view_properties: {"stand_alone": true, brand_value: "NetScaler MAS NITRO API Documentation"}
    }
};

rdx.page.add_event_handler(rdx.events.APP_LOADED, new rdx.callback(function() {
    rdx.images.COMPANY_LOGO_IMG = "rdx/images/company_logo.png";
    //Hack to avoid showing status bar
    rdx.status_bar._status = $("<div>");
}));

rdx.page.add_event_handler(rdx.events.PAGE_LOADED, new rdx.callback(null, function() {
    //Hack to show build info on the top-right corner of header
	var build_value = "("+version+": " + "Build " +build+")";
    $(".ns_logo_version").append($("<span>").addClass("build_version").append(build_value));

    var tree_nodes =
    [
		new rdx.tree_node({
            name: "Introduction",
            view:
            {
                type: rdx.view_constants.URL_VIEW,
                url: "doc/getting_started_guide_rest.pdf"
            },
            nodes:
            [
            	new rdx.tree_node({
								name: "Getting Started Guide",
								view:
								{
									type: rdx.view_constants.URL_VIEW,
									url: "doc/getting_started_guide_rest.pdf"
					}}),
				new rdx.tree_node({
					name: "Configuration",
					view:
					{
						type: rdx.view_constants.URL_VIEW,
						url: "html/config_list_mps_v1.html"
					},
					nodes :
						[
						new rdx.tree_node({
							name: "Version v1",
							view:
							{
								type: rdx.view_constants.URL_VIEW,
								url: "html/config_list_mps_v1.html"
							},

							nodes:
								[	
								new rdx.tree_node({
									name: "mps",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_mps_v1.html"
									},
									nodes: config_tree_nodes_v1
								}),
								new rdx.tree_node({
									name: "ns",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_ns_v1.html"
									},
									nodes: config_tree_nodes_ns_v1
								}),
								new rdx.tree_node({
									name: "sdx",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_sdx_v1.html"
									},
									nodes: config_tree_nodes_sdx_v1
								}),
								new rdx.tree_node({
									name: "cbwanopt",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_cbwanopt_v1.html"
									},
									nodes: config_tree_nodes_cbwanopt_v1
								}),
								new rdx.tree_node({
									name: "sdwanvw",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_sdwanvw_v1.html"
									},
									nodes: config_tree_nodes_sdwanvw_v1
								}),
								new rdx.tree_node({
									name: "services",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_services_perf_v1.html"
									},
									nodes:[
										new rdx.tree_node({
											name: "perf",
											view:
											{
												type: rdx.view_constants.URL_VIEW,
												url: "html/config_list_services_perf_v1.html"
											},
											nodes: config_tree_nodes_services_perf_v1
										})
									]
								}),
								new rdx.tree_node({
									name: "stylebooks",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_stylebooks_v1.html"
									},
									nodes: config_tree_nodes_stylebooks_v1
								})
							]
						}),
						new rdx.tree_node({
							name: "Version v2",
							view:
							{
								type: rdx.view_constants.URL_VIEW,
								url: "html/config_list_mps_v2.html"
							},

							nodes:
								[	
								new rdx.tree_node({
									name: "mps",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_mps_v2.html"
									},
									nodes: config_tree_nodes_v2
								}),
								new rdx.tree_node({
									name: "ns",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_ns_v2.html"
									},
									nodes: config_tree_nodes_ns_v2
								}),
								new rdx.tree_node({
									name: "sdx",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_sdx_v2.html"
									},
									nodes: config_tree_nodes_sdx_v2
								}),
								new rdx.tree_node({
									name: "cbwanopt",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_cbwanopt_v2.html"
									},
									nodes: config_tree_nodes_cbwanopt_v2
								}),
								new rdx.tree_node({
									name: "sdwanvw",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_sdwanvw_v2.html"
									},
									nodes: config_tree_nodes_sdwanvw_v2
								}),
								new rdx.tree_node({
									name: "services",
									view:
									{
										type: rdx.view_constants.URL_VIEW,
										url: "html/config_list_services_perf_v2.html"
									},
									nodes:[
										new rdx.tree_node({
											name: "perf",
											view:
											{
												type: rdx.view_constants.URL_VIEW,
												url: "html/config_list_services_perf_v2.html"
											},
											nodes: config_tree_nodes_services_perf_v2
										})
									]
								})
							]
					})]
				}),
				new rdx.tree_node({
					name: "Appendix",
					view:
					{
						type: rdx.view_constants.URL_VIEW,
						url: "doc/errorlisting.html"
					},
					nodes:
					[
						new rdx.tree_node({
							name: "Error Messages",
							view:
							{
								type: rdx.view_constants.URL_VIEW,
								url: "doc/errorlisting.html"
							}
						})
					]
				})
            ]
        }),

  ];
    var tree = new rdx.tree(rdx.page.get_content(), tree_nodes, {tree_pane_min_width: 260, show_expand_collapse_all: true});
    tree.render();
    //Hack to not show bread crumbs (as it works unexpectedly)
    $(".title_tool_bar_table").hide();
}));