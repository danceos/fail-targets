set @variant = 'riscv32/main';

SELECT count(*) from trace where variant_id in (SELECT id FROM variant where variant = @variant and benchmark in ("regs-trace"));
SELECT count(*) from trace where variant_id in (SELECT id FROM variant where variant = @variant and benchmark in ("regs", "ip"));
SELECT count(*),
       sum(t1.instr1 != t2.instr1) as instr1,
       sum(t1.time1 != t2.time1) as time1,
       sum(t1.time2 != t2.time2) as time2,
       sum(t1.instr1_absolute != t2.instr1_absolute) as instr1_absolute,
       sum(t1.instr2_absolute != t2.instr2_absolute) as instr2_absolute,
       sum(t1.data_address != t2.data_address) as data_address
  FROM trace t1
  JOIN trace t2 ON t1.instr2 = t2.instr2 AND t1.data_address = t2.data_address
  WHERE
        t1.variant_id in (SELECT id FROM variant where variant = @variant and benchmark in ("regs", "ip"))
     and
        t2.variant_id in (SELECT id FROM variant where variant = @variant and benchmark in ("regs-trace"));
  ;

