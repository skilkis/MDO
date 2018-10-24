p.point1 = [0, 0, 0];
p.point2 = [0, 1, 0];
p.point3 = [1, 1, 0];
p.point4 = [1, 0, 0];
p.point5 = [0.5, 0.5, 1];

cases = {'point1', 'point2', 'point3', 'point4', 'point5'};
x = [];
y = [];
z = [];
i = 1;
% Iteration over cases, THE SIMPLE WAY
for j = cases
    point = p.(j{1});
    disp(point)
    x(i) = point(1);
    y(i) = point(2);
    z(i) = point(3);
    i = i + 1;
end
% 
[K, V] = convhull(x,y,z);

surf(x(K), y(K), z(K))