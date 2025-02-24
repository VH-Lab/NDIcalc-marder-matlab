classdef contrast_tuning < ndi.calculator

	methods
		function contrast_tuning_obj = contrast_tuning(session)
			% CONTRAST_TUNING - a contrast_tuning demonstration of an ndi.calculator object
			%
			% CONTRAST_TUNING_OBJ = CONTRAST_TUNING(SESSION)
			%
			% Creates a CONTRAST_TUNING ndi.calculator object
			%
				ndi.globals;
				w = which('ndi.calc.vis.contrast_tuning');
				parparparpar = fileparts(fileparts(fileparts(fileparts(w))));
				contrast_tuning_obj = contrast_tuning_obj@ndi.calculator(session,'contrasttuning_calc',...
					fullfile(parparparpar,'ndi_common','database_documents','calc','contrasttuning_calc.json'));
		end; % contrast_tuning()

		function doc = calculate(ndi_calculator_obj, parameters)
			% CALCULATE - perform the calculator for ndi.calc.example.contrast_tuning
			%
			% DOC = CALCULATE(NDI_CALCULATOR_OBJ, PARAMETERS)
			%
			% Creates a contrast_tuning_calc document given input parameters.
			%
			% The document that is created contrast_tuning
			% by the input parameters.
				% check inputs
				if ~isfield(parameters,'input_parameters'), error(['parameters structure lacks ''input_parameters''.']); end;
				if ~isfield(parameters,'depends_on'), error(['parameters structure lacks ''depends_on''.']); end;
				
				% Step 1: set up the output structure
				contrast_tuning_calc = parameters;

				tuning_response_doc = ndi_calculator_obj.session.database_search(ndi.query('base.id','exact_string',...
					did.db.struct_name_value_search(parameters.depends_on,'stimulus_tuningcurve_id'),''));
				if numel(tuning_response_doc)~=1, 
					error(['Could not find stimulus tuning doc..']);
				end;
				tuning_response_doc = tuning_response_doc{1};

				% Step 2: perform the calculator, which here creates a contrast_tuning doc
				doc = ndi_calculator_obj.calculate_contrast_indexes(tuning_response_doc) + ...
					ndi_calculator_obj.newdocument();

				if isempty(doc.document_properties.contrast_tuning.significance.visual_response_anova_p),
				end;
				
				if ~isempty(doc), 
					doc = ndi.document(ndi_calculator_obj.doc_document_types{1},'contrasttuning_calc',contrast_tuning_calc) + doc;
				end;
		end; % calculate

		function parameters = default_search_for_input_parameters(ndi_calculator_obj)
			% DEFAULT_SEARCH_FOR_INPUT_PARAMETERS - default parameters for searching for inputs
			%
			% PARAMETERS = DEFAULT_SEARCH_FOR_INPUT_PARAMETERS(NDI_CALCULATOR_OBJ)
			%
			% Returns a list of the default search parameters for finding appropriate inputs
			% to the calculator. For contrast_tuning_calc, there is no appropriate default parameters
			% so this search will yield empty.
			%
				parameters.input_parameters = struct([]);
				parameters.depends_on = did.datastructures.emptystruct('name','value');
				parameters.query = ndi_calculator_obj.default_parameters_query(parameters);
					
		end; % default_search_for_input_parameters

                function query = default_parameters_query(ndi_calculator_obj, parameters_specification)
			% DEFAULT_PARAMETERS_QUERY - what queries should be used to search for input parameters if none are provided?
			%
			% QUERY = DEFAULT_PARAMETERS_QUERY(NDI_CALCULATOR_OBJ, PARAMETERS_SPECIFICATION)
			%
			% When one calls SEARCH_FOR_INPUT_PARAMETERS, it is possible to specify a 'query' structure to
			% select particular documents to be placed into the parameters 'depends_on' specification.
			% If one does not provide any 'query' structure, then the default values here are used.
			%
			% The function returns:
			% |-----------------------|----------------------------------------------|
			% | query                 | A structure with 'name' and 'query' fields   |
			% |                       |   that describes a search to be performed to |
			% |                       |   identify inputs for the 'depends_on' field |
			% |                       |   in the PARAMETERS output.                  |
			% |-----------------------|-----------------------------------------------
			%
			% For the ndi.calc.stimulus.contrast_tuning_calc class, this looks for 
			% documents of type 'stimulus_response_scalar' with 'response_type' fields
			% the contain 'mean' or 'F1'.
			%
			%
				q1 = ndi.query('','isa','stimulus_tuningcurve','');
				q2 = ndi.query('stimulus_tuningcurve.independent_variable_label','contains_string','contrast','');
				q3 = ndi.query('stimulus_tuningcurve.independent_variable_label','contains_string','Contrast','');
				q4 = ndi.query('stimulus_tuningcurve.independent_variable_label','contains_string','CONTRAST','');
				q234 = q2 | q3 | q4;
				q_total = q1 & q234;

				query = struct('name','stimulus_tuningcurve_id','query',q_total);
		end; % default_parameters_query()

		function b = is_valid_dependency_input(ndi_calculator_obj, name, value)
			% IS_VALID_DEPENDENCY_INPUT - is a potential dependency input actually valid for this calculator?
			%
			% B = IS_VALID_DEPENDENCY_INPUT(NDI_CALCULATOR_OBJ, NAME, VALUE)
			%
			% Tests whether a potential input to a calculator is valid.
			% The potential dependency name is provided in NAME and its base id is
			% provided in VALUE.
			%
			% The base class behavior of this function is simply to return true, but it
			% can be overriden if additional criteria beyond an ndi.query are needed to
			% assess if a document is an appropriate input for the calculator.
			%
				b = 1;
				return;

				% could also use the below, but will require an extra query operation
	
				switch lower(name),
					case lower('stimulus_tuningcurve_id'),
						q = ndi.query('base.id','exact_string',value,'');
						d = ndi_calculator_obj.S.database_search(q);
						b = (numel(d.document_properties.independent_variable_label) ==1);
					case lower('element_id'),
						b = 1;
				end;
		end; % is_valid_dependency_input()

		function h=plot(ndi_calculator_obj, doc_or_parameters, varargin)
                        % PLOT - provide a diagnostic plot to show the results of the calculator
                        %
                        % H=PLOT(NDI_CALCULATOR_OBJ, DOC_OR_PARAMETERS, ...)
                        %
                        % Produce a plot of the tuning curve.
			%
                        % Handles to the figure, the axes, and any objects created are returned in H.
                        %
                        % This function takes additional input arguments as name/value pairs.
                        % See ndi.calculator.plot_parameters for a description of those parameters.
                        % 
                        % Additional name/value pairs are:
                        % -------------------------------------------------------------------------
                        % | Parameter (default)            | Description                          |
                        % |--------------------------------|--------------------------------------|
                        % | Display_element_name (1)       | 0/1 Should we display the element    |
                        % |                                |    name in the title?                |
                        % |--------------------------------|--------------------------------------|
                        %
                        %

				% call superclass plot method to set up axes
				h=plot@ndi.calculator(ndi_calculator_obj, doc_or_parameters, varargin{:});
                Display_element_name = 1;
                did.datastructures.assign(varargin{:});

				if isa(doc_or_parameters,'ndi.document'),
					doc = doc_or_parameters;
				else,
					error(['Do not know how to proceed without an ndi document for doc_or_parameters.']);
				end;

				ct = doc.document_properties.contrast_tuning; % shorten our typing
				tc = ct.tuning_curve; % shorten our typing
				ft = ct.fit;

				% First plot responses
				hold on;
				h_baseline = plot([min(tc.contrast) max(tc.contrast)],...
					[0 0],'k--','linewidth',1.0001);
				h_baseline.Annotation.LegendInformation.IconDisplayStyle = 'off';
				h.objects(end+1) = h_baseline;
				[v,sortorder] = sort(tc.contrast);
				h_errorbar = errorbar(tc.contrast(sortorder(:)),...
					tc.mean(sortorder(:)),tc.stderr(sortorder(:)),tc.stderr(sortorder(:)));
				set(h_errorbar,'color',[0 0 0],'linewidth',1,'linestyle','none');
				h.objects = cat(2,h.objects,h_errorbar);
				
				% Second plot all fits

				h.objects(end+1) = plot(ft.naka_rushton_RB_contrast,ft.naka_rushton_RB_values,'-','color',0.33*[1 0 1],...
					'linewidth',1.5);
				h.objects(end+1) = plot(ft.naka_rushton_RBN_contrast,ft.naka_rushton_RBN_values,'-','color',0.67*[1 0 1],...
					'linewidth',1.5);
				h.objects(end+1) = plot(ft.naka_rushton_RBNS_contrast,ft.naka_rushton_RBNS_values,'-','color',1*[1 0 1],...
					'linewidth',1.5);

				if ~h.params.suppress_x_label,
					h.xlabel = xlabel('Contrast');
				end;
				if ~h.params.suppress_y_label,
					h.ylabel = ylabel(['Response (' ct.properties.response_type ', ' ct.properties.response_units ')']);
				end;

				if Display_element_name,
					if ~h.params.suppress_title,
						element = ndi.database.fun.ndi_document2ndi_object(doc.dependency_value('element_id'),ndi_calculator_obj.session);
						h.title = title(element.elementstring(), 'interp','none');
					end;
				end;
				box off;

		end; % plot()

		function contrast_props_doc = calculate_contrast_indexes(ndi_calculator_obj, tuning_doc)
			% CALCULATE_CONTRAST_INDEXES - calculate contrast index values from a tuning curve
			%
			% CONTRAST_PROPS_DOC = CALCULATE_CONTRAST_INDEXES(NDI_CONTRAST_TUNING_CALC_OBJ, TUNING_DOC)
			%
			% Given a 1-dimensional tuning curve document, this function calculates contrast response
			% parameters and stores them in CONTRAST_TUNING document CONTRAST_PROPS_DOC.
			%
			%
				properties.response_units = tuning_doc.document_properties.stimulus_tuningcurve.response_units;
				
				stim_response_doc = ndi_calculator_obj.session.database_search(ndi.query('base.id',...
					'exact_string',tuning_doc.dependency_value('stimulus_response_scalar_id'),''));
				if numel(stim_response_doc)~=1,
					error(['Could not find stimulus response scalar document.']);
				end;
				if iscell(stim_response_doc),
					stim_response_doc = stim_response_doc{1};
				end;

				properties.response_type = stim_response_doc.document_properties.stimulus_response_scalar.response_type;

				resp = ndi.app.stimulus.tuning_response.tuningcurvedoc2vhlabrespstruct(tuning_doc);

				[anova_across_stims, anova_across_stims_blank] = neural_response_significance(resp);

				tuning_curve = struct(...
					'contrast', ...
						vlt.data.colvec(tuning_doc.document_properties.stimulus_tuningcurve.independent_variable_value), ...
					'mean', vlt.data.colvec(resp.curve(2,:)), ...
					'stddev', vlt.data.colvec(resp.curve(3,:)), ...
					'stderr', vlt.data.colvec(resp.curve(4,:)), ...
					'individual', vlt.data.cellarray2mat(resp.ind), ...
					'control_stddev', resp.blankresp(2),...
					'control_stderr', resp.blankresp(3));

				significance = struct('visual_response_anova_p',anova_across_stims_blank,...
					'across_stimuli_anova_p', anova_across_stims);

				fitless.interpolated_c50 = vis.contrast.indexes.c50interpolated(tuning_curve.contrast,...
					tuning_curve.mean);

				prefixes = {'naka_rushton_RB_','naka_rushton_RBN_', 'naka_rushton_RBNS_'};
				fitterms = 2:4;

				fit = struct([]);

				fit(1).naka_rushton_RB_parameters = [];

				for f = 1:numel(fitterms),
					fi = vis.contrast.indexes.fitindexes(resp,fitterms(f));
					fit = setfield(fit,[prefixes{f} 'parameters'],vlt.data.colvec(fi.fit_parameters));
					fit = setfield(fit,[prefixes{f} 'contrast'],vlt.data.colvec(fi.fit(1,:)));
					fit = setfield(fit,[prefixes{f} 'values'],vlt.data.colvec(fi.fit(2,:)));
					[m,pref_index] = max(fi.fit(2,:));
					pref = fi.fit(1,pref_index);
					fit = setfield(fit,[prefixes{f} 'pref'], pref);
					fit = setfield(fit,[prefixes{f} 'empirical_c50'], fi.empirical_C50);
					fit = setfield(fit,[prefixes{f} 'r2'], fi.r2);
					fit = setfield(fit,[prefixes{f} 'relative_max_gain'], fi.relative_max_gain);
					fit = setfield(fit,[prefixes{f} 'saturation_index'], fi.saturation_index);
					fit = setfield(fit,[prefixes{f} 'sensitivity'], vlt.data.colvec(fi.sensitivity));
				end;

				contrast_tuning.properties = properties;
				contrast_tuning.tuning_curve = tuning_curve;
				contrast_tuning.significance = significance;
				contrast_tuning.fitless = fitless;
				contrast_tuning.fit = fit;

				contrast_props_doc = ndi.document('contrast_tuning',...
					'contrast_tuning',contrast_tuning);
				contrast_props_doc = contrast_props_doc.set_dependency_value('element_id', ...
					tuning_doc.dependency_value('element_id'));
				contrast_props_doc = contrast_props_doc.set_dependency_value('stimulus_tuningcurve_id',tuning_doc.id());

		end; % calculate_contrast_indexes()
        % TESTING METHODS

		function [docs, doc_output, doc_expected_output] = generate_mock_docs(contrast_calc_obj, scope, number_of_tests, varargin)
			% GENERATE_MOCK_DOCS - generate mock documents and expected answers for tests
			%
			% [DOCS, DOC_OUTPUT, DOC_EXPECTED_OUTPUT] = GENERATE_MOCK_DOCS(CONTRAST_CALC_OBJ, ...
			%    SCOPE, NUMBER_OF_TESTS, ...)
			%
			% Creates a set of documents to test ndi.calc.vis.contrast_tuning.
			%
			% SCOPE is the scope to be tested: 'standard', 'low_noise', 'high_noise'
			% NUMBER_OF_TESTS indicates the number of tests to be performed.
			%
			% DOCS{i} is the set of helper documents that may have been created
			%   in generating the ith test.
			% DOC_OUTPUT{i} is the actual output of the calculator when operating on
			%   DOCS{i} (the ith test).
			% DOC_EXPECTED_OUTPUT{i} is what the output of the calculator should be, if there
			%   were no noise. If these documents are plotted, they must be plotted
            %   with Display_element_name set to 0 in PLOT.            %   
			%
			% The quality of these outputs are evaluted using the function COMPARE_MOCK_DOCS
			% as part of the TEST function for ndi.calculator objects.
			%
			% This function's behavior can be modified by name/value pairs.
			% --------------------------------------------------------------------------------
			% | Parameter (default):     | Description:                                      |
			% |--------------------------|---------------------------------------------------|
			% | generate_expected_docs(0)| Should we generate the expected docs? (That is,   |
			% |                          |   generate the "right answer"?) Use carefully.    |
			% |--------------------------|---------------------------------------------------|
			%

				generate_expected_docs = 0;
				vlt.data.assign(varargin{:});

				docs = {};
				doc_output = {};
				doc_expected_output = {};

				for i=1:number_of_tests,
					docs{i} = {};
                    S = contrast_calc_obj.session;
					[rmax,c50,N,s] = contrast_calc_obj.generate_mock_parameters(scope, i);
                    numsteps = 10; %sets size of x
					contrasts = logspace(-1,0,numsteps); % generates a row vector of 'numsteps' logarithmically equally spaced points between 10^-1 and 10^0
					
                    r = rmax * vlt.fit.naka_rushton_func(contrasts,c50,N,s);
                    %param_struct = struct([]); %this didn't work - need at
                    %least one parameter?
                    param_struct = struct('spatial_frequency',0.5);
					independent_variable = {'contrast'};
					x = contrasts(:); % column
					r = r(:); % column
					x(end+1,1) = NaN;
					r(end+1,1) = 0;
					
					switch (scope),
						case 'standard',
							reps = 5; % need reps to test significance measures
							noise = 0;
						case 'low_noise',
							reps = 10;
							noise = 0.1;
						case 'high_noise',
							reps = 10;
							noise = 1;
						otherwise,
							error(['Unknown scope ' scope '.']);
					end; % switch

					docs{i} = ndi.mock.fun.stimulus_response(S,...
						param_struct, independent_variable, x, r, noise, reps);

                    calcparameters = contrast_calc_obj.default_search_for_input_parameters();
                    calcparameters.query.query = ndi.query('stimulus_tuningcurve.independent_variable_label','contains_string','contrast','');
					calcparameters.query.query = calcparameters.query.query & ...
						ndi.query('','depends_on','element_id',docs{i}{3}.id());
                    I = contrast_calc_obj.search_for_input_parameters(calcparameters);
                    doc_output{i} = contrast_calc_obj.run('Replace',calcparameters);
					if numel(doc_output{i})>1,
						error(['Generated more than one output doc when one was expected.']);
                    elseif numel(doc_output{i})==0,
						error(['Generated no output docs when one was expected.']);
					end;
					doc_output{i} = doc_output{i}{1};

					if generate_expected_docs,
						contrast_calc_obj.write_mock_expected_output(i,doc_output{i});
					end;

					doc_expected_output{i} = contrast_calc_obj.load_mock_expected_output(i);

				end; % for
		end; % generate_mock_docs()

		function [b,errormsg] = compare_mock_docs(oridir_calc_obj, expected_doc, actual_doc, scope)
			% COMPARE_MOCK_DOCS - compare an expected calculation answer with an actual answer
			%
			% [B, ERRORMSG] = COMPARE_MOCK_DOCS(CTEST_OBJ, EXPECTED_DOC, ACTUAL_DOC, SCOPE)
			%
			% Given an NDI document with the expected answer to a calculation (EXPECTED_DOC),
			% the ACTUAL_DOC computed, and the SCOPE (a string: 'standard', 'low_noise','high_noise'),
			% this function computes whether the ACTUAL_DOC is within an allowed tolerance of
			% EXPECTED_DOC.
			%
			% B is 1 if the differences in the documents are within the tolerance of the class.
			% Otherwise, B is 0.
			% If B is 0, ERRORMSG is a string that indicates where the ACTUAL_DOC is out of tolerance.
			%

				[b_,errormsg] = ndi.calc.vis.test.contrast_tuning_compare_docs(expected_doc,actual_doc,scope);			
                errormsg = cat(2,errormsg{:}); %removes extra errormsg cells
                b = ~isempty(find(b_, 1)); %b is 1 if b_ has no 0s, i.e. there are no errors - can also use b = all(b)
		end;

		function [rmax, c50, N, s, total] = generate_mock_parameters(oridir_calc_obj, scope, index)
			% generate_mock_parameters - generate mock parameters for testing ndi.calc.vis.contrast_tuning
			%
			% [RMAX, C50, N, S, TOTAL] = ndi.calc.vis.generate_mock_parameters(scope, index)
			%
			% Generates a parameter set for generating a mock document with a given index value.
            % RMAX is the maximum response
            % C50 is the half-maximum contrast
            % N is the exponent parameter that sets the shape
            % S is the degree of supersaturation
			% TOTAL is the total number of mock stimuli that are available to be generated.
			% 
			% INDEX selects which parameters are used to generate a mock document (from 1...TOTAL).
			% 

				P_(1,:) = [ 10 .45 1.5 1 ] ; % saturated and conventional forms should both fit the data equally well
                P_(2,:) = [ 10 .45 1.5 2 ] ; % supersaturated
                P_(3,:) = [ 10 .45 1.5 .5 ] ; % unsaturated
                P_(4,:) = [ 20 .45 1.5 2 ] ; % supersaturated and higher firing rate
                P_(5,:) = [ 5 .45 1.5 2 ] ; % supersaturated and lower firing rate
                P_(6,:) = [ 10 .45 1 2 ] ; % lower N
                P_(7,:) = [ 10 .45 2 2 ] ; % higher N
                P_(8,:) = [ 10 .75 1.5 2 ] ; % higher c50
                P_(9,:) = [ 10 .25 1.5 2 ] ; % lower c50 (but not too low that responses don't make sense)
					% potentially add more
				total = size(P_,1);

				actual_index = 1+mod(index-1,total);

				% no dependence on scope for this stimulus type
                
				P = P_(actual_index,:);
                rmax = P(1);
                c50 = P(2);
                N = P(3);
                s = P(4);
		end; % generate_mock_parameters
	end; % methods()
end % contrast_tuning
