function f = tryout(x, a, b)
  f = [exp(-x(1)) - x(1)*a; exp(-b*x(2)) - x(2)];
end