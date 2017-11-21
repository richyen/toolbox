#!/bin/sh

while :
do
  psql -Atc "update pm_paymentengine.fintrans1 set merchantid='foo' where systemid=(select systemid from pm_paymentengine.fintrans1 limit 1)"
  sleep 1
done
