SELECT ename, sale_date, customer_name, sale_amount
  FROM sales s
  JOIN emp e ON e.empno=s.salesperson
  JOIN jobhist j ON j.empno=e.empno
 WHERE date_part('month',sale_date) > 9
   AND j.startdate between '1980-01-01' and '1985-01-01'
   AND sale_amount > 90
 ORDER BY sale_amount DESC;
