function count = linecount(filename)
%LINECOUNT Returns the number of data-lines in a data file
% From: https://nl.mathworks.com/matlabcentral/answers/81137-pre-
% determining-the-number-of-lines-in-a-text-file
    count = 0;
    fid = fopen(filename);
    while ~feof(fid)
       if ischar(fgetl(fid))
            count = count + 1;
       end
    end
    fclose(fid);
end

