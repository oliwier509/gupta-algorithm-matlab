function gupta_gui
    % GUI to input processing times and compute Gupta algorithm results
    f = figure('Position', [300 300 600 500], 'Name', 'Gupta Algorithm UI');

    % UI elements for matrix size
    uicontrol(f, 'Style', 'text', 'Position', [58 450 120 20], 'String', 'wiersze:');
    rowInput = uicontrol(f, 'Style', 'edit', 'Position', [140 450 50 25]);

    uicontrol(f, 'Style', 'text', 'Position', [248 450 100 20], 'String', 'kolumny:');
    colInput = uicontrol(f, 'Style', 'edit', 'Position', [320 450 50 25]);

    generateBtn = uicontrol(f, 'Style', 'pushbutton', 'Position', [400 450 150 25], ...
                            'String', 'Generuj Macierz', 'Callback', @generateMatrixFields);

    matrixFields = [];

    function generateMatrixFields(~, ~)
        % Clear previous fields
        % Check if matrixFields is not empty and contains valid handles
        if ~isempty(matrixFields) && isvalid(matrixFields(1)) % Sprawdzamy, czy macierz nie jest pusta i czy pierwszy uchwyt jest poprawny
            for i = 1:size(matrixFields, 1)
                for j = 1:size(matrixFields, 2)
                    % Check if the handle is valid before deleting
                    if isvalid(matrixFields(i,j))
                        delete(matrixFields(i,j));
                    end
                end
            end
        end
        % Clear the matrixFields variable after deleting objects
        matrixFields = gobjects(0); % Reset do pustej tablicy obiektów graficznych

        % Clear the previous 'Oblicz' button if it exists
        % Znajdujemy przycisk po jego tekście i typie
        computeBtn = findobj(f, 'String', 'Oblicz', 'Style', 'pushbutton');
        % Sprawdzamy, czy znaleziono przycisk i czy jest ważny
        if ~isempty(computeBtn) && isvalid(computeBtn)
            delete(computeBtn);
        end


        rows = str2double(get(rowInput, 'String'));
        cols = str2double(get(colInput, 'String'));

        if isnan(rows) || isnan(cols) || rows <= 0 || cols <= 0
            errordlg('Błąd danych wejściowych', 'Input Error');
            % Upewniamy się, że matrixFields i computeBtn są wyczyszczone,
            % nawet jeśli wprowadzono błędne dane po poprzednim wygenerowaniu
            matrixFields = gobjects(0);
            computeBtn = findobj(f, 'String', 'Oblicz', 'Style', 'pushbutton');
            if ~isempty(computeBtn) && isvalid(computeBtn)
                delete(computeBtn);
            end
            return;
        end

        matrixFields = gobjects(rows, cols); % Re-initialize for new fields

        startX = 30;
        startY = 380;
        boxW = 40;
        boxH = 25;
        spacing = 10;

        for i = 1:rows
            for j = 1:cols
                matrixFields(i,j) = uicontrol(f, 'Style', 'edit', ...
                    'Position', [startX + (j-1)*(boxW+spacing), ...
                                 startY - (i-1)*(boxH+spacing), ...
                                 boxW, boxH]);
            end
        end

        % Create the new 'Oblicz' button
        uicontrol(f, 'Style', 'pushbutton', 'Position', [startX, startY - rows*(boxH+spacing) - 30, 150, 30], ...
                  'String', 'Oblicz', 'Callback', @runGupta);
    end

    function runGupta(~, ~)
        rows = size(matrixFields, 1);
        cols = size(matrixFields, 2);
        processing_times = zeros(rows, cols);

        for i = 1:rows
            for j = 1:cols
                val = str2double(get(matrixFields(i,j), 'String'));
                if isnan(val)
                    errordlg('Błąd danych w macierzy', 'Input Error');
                    return;
                end
                processing_times(i,j) = val;
            end
        end

        [job_order, g_details, Cmax] = gupta_algorithm(processing_times);

        msg = sprintf('Kolejność: %s\nCmax: %d', mat2str(job_order), Cmax);
        msgbox(msg, 'Results');
    end
end

function [job_order, g_details, Cmax] = gupta_algorithm(processing_times)
    [num_machines, num_jobs] = size(processing_times);
    g_values = zeros(num_jobs, 2); % Store index and G_j

    for j = 1:num_jobs
        t_first = processing_times(1, j);
        t_last = processing_times(end, j);

        A = 1;
        if t_last > t_first
            A = -1;
        end

        min_sum = inf;
        for i = 1:(num_machines - 1)
            current_sum = processing_times(i, j) + processing_times(i + 1, j);
            if current_sum < min_sum
                min_sum = current_sum;
            end
        end

        g_j = A / min_sum;
        g_values(j, :) = [j, g_j];
    end

    sorted_g_values = sortrows(g_values, 2);
    job_order = sorted_g_values(:, 1)';

    Cmax = compute_makespan(processing_times, job_order);
    g_details = sorted_g_values;
end

function Cmax = compute_makespan(processing_times, sequence)
    [num_machines, num_jobs] = size(processing_times);
    completion = zeros(num_machines, num_jobs);

    completion(1, 1) = processing_times(1, sequence(1));
    for j = 2:num_jobs
        completion(1, j) = completion(1, j - 1) + processing_times(1, sequence(j));
    end

    for i = 2:num_machines
        completion(i, 1) = completion(i - 1, 1) + processing_times(i, sequence(1));
        for j = 2:num_jobs
            completion(i, j) = max(completion(i - 1, j), completion(i, j - 1)) + processing_times(i, sequence(j));
        end
    end

    Cmax = completion(end, end);
end