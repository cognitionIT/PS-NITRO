rdx.views =
{
    header_view:
    {
        type: rdx.view_constants.HEADER_VIEW,
        view_properties: {"stand_alone": true, brand_value: "NetScaler NITRO API Documentation"}
    }
};

rdx.page.add_event_handler(rdx.events.APP_LOADED, new rdx.callback(function() {
    rdx.images.COMPANY_LOGO_IMG = "rdx/images/company_logo.png";
    //Hack to avoid showing status bar
    rdx.status_bar._status = $("<div>");
}));

rdx.page.add_event_handler(rdx.events.PAGE_LOADED, new rdx.callback(null, function() {
    //Hack to show build info on the top-right corner of header
    var build_value = "(NS"+version+": " + "Build " +build+")";
    $(".ns_logo_version").append($("<span>").addClass("build_version").append(build_value));

    var tree_nodes =
    [
		new rdx.tree_node({
            name: "Introduction",
            view:
            {
                type: rdx.view_constants.URL_VIEW,
                url: "./doc/getting_started_guide_rest.pdf"
            },
            nodes:
            [
                new rdx.tree_node({
                    name: "Getting Started Guide",
                    view:
                    {
                        type: rdx.view_constants.URL_VIEW,
                        url: "./doc/getting_started_guide_rest.pdf"
                    }}),

					 new rdx.tree_node({
					name: "Configuration",
					view:
					{
						type: rdx.view_constants.URL_VIEW,
						url: "html/config/config_pkg_list.html"
					},
					nodes: config_tree_nodes
				}),
				new rdx.tree_node({
					name: "Statistics",
					view:
					{
						type: rdx.view_constants.URL_VIEW,
						url: "html/stat/stat_pkg_list.html"
					},
					nodes: stat_tree_nodes
				}),
				new rdx.tree_node({
					name: "Appendix",
					view:
					{
						type: rdx.view_constants.URL_VIEW,
						url: "html/errorlisting.html"
					},
					nodes:
					[
						new rdx.tree_node({
							name: "Error Messages",
							view:
							{
								type: rdx.view_constants.URL_VIEW,
								url: "html/errorlisting.html"
							}
						})
					]
                })
            ]
        })
    ];
    var tree = new rdx.tree(rdx.page.get_content(), tree_nodes, {tree_pane_min_width: 260, show_expand_collapse_all: true});
    tree.render();
    //Hack to not show bread crumbs (as it works unexpectedly)
    $(".title_tool_bar_table").hide();
}));