filepath = 'result.csv';

cells = model.stackPredictionBoxes;
fid = fopen('result.csv', 'w');
fprintf(fid,'z,x,y,width,height,united\r\n');
for i = 1:numel(cells)
    fprintf(fid, '%d,%d,%d,%d,%d,%d\r\n', cells(i).z, round(cells(i).BoundingBox(1)), round(cells(i).BoundingBox(2)), ...
        cells(i).BoundingBox(3), cells(i).BoundingBox(4), cells(i).color);
end
fclose(fid);