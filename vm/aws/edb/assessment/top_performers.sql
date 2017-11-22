SELECT ename, sale_date, customer_name, sale_amount
  FROM sales s
  JOIN emp e ON e.empno=s.salesperson
  JOIN jobhist j ON j.empno=e.empno
 WHERE sale_date > now() - interval '1 month'
   AND j.startdate between '1980-01-01' and '1985-01-01'
 ORDER BY sale_amount
  DESC limit 10;
