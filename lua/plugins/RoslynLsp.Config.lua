return {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            roslyn = {
                settings = {
                    ["csharp|background_analysis"] = {
                        dotnet_analyzer_diagnostics_scope = "fullSolution",
                        dotnet_compiler_diagnostics_scope = "fullSolution",
                    },

                    ["csharp|inlay_hints"] = {
                        csharp_enable_inlay_hints_for_implicit_variable_types = true,
                        csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                        csharp_enable_inlay_hints_for_types = true,
                        dotnet_enable_inlay_hints_for_indexer_parameters = true,
                        dotnet_enable_inlay_hints_for_literal_parameters = true,
                        dotnet_enable_inlay_hints_for_object_creation_parameters = true,
                        dotnet_enable_inlay_hints_for_other_parameters = true,
                        dotnet_enable_inlay_hints_for_parameters = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
                    },

                    ["csharp|completion"] = {
                        dotnet_show_completion_items_from_unimported_namespaces = true,
                        dotnet_provide_regex_completions = true,
                        dotnet_show_name_completion_suggestions = true,
                    },

                    ["csharp|quick_info"] = {
                        dotnet_show_remarks_in_quick_info = true,
                    },

                    ["csharp|formatting"] = {
                        dotnet_organize_imports_on_format = true,
                    },

                    ["csharp|code_lens"] = {
                        dotnet_enable_references_code_lens = true,
                        dotnet_enable_tests_code_lens = true,
                    },

                    ["navigation"] = {
                        dotnet_navigate_to_decompiled_sources = true,
                    },

                    ["csharp|auto_insert"] = {
                        dotnet_enable_auto_insert = true,
                    },
                },
            },
        },
    },
}
