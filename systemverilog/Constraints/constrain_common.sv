class myClass;
      rand bit [3:0] min, typ, max;
      rand bit [3:0] fixed;

      // 宣告一個各個變數有相依性的限制
      // 一行限制只能存在一個表達式 (ex: <, >, == ...)
      constraint my_range { 3 < min;
                            typ < max;
                            typ > min;
                            max < 14; }

      constraint c_fixed { fixed == 5; }

      function string display ();
        return $sformatf ("min=%0d typ=%0d max=%0d fixed=%d", min, typ, max, fixed);
      endfunction

endclass

module tb;
    initial begin
        for (int i = 0; i < 10; i++) begin
            myClass cls = new ();
            cls.randomize();
            $display ("itr=%0d %s", i, cls.display());
        end
    end
endmodule


/*
itr=0 min=7 typ=9 max=12 fixed= 5
itr=1 min=4 typ=9 max=12 fixed= 5
itr=2 min=7 typ=10 max=13 fixed= 5
itr=3 min=4 typ=6 max=11 fixed= 5
itr=4 min=8 typ=12 max=13 fixed= 5
itr=5 min=5 typ=6 max=13 fixed= 5
itr=6 min=6 typ=9 max=13 fixed= 5
itr=7 min=10 typ=12 max=13 fixed= 5
itr=8 min=5 typ=11 max=13 fixed= 5
itr=9 min=6 typ=9 max=11 fixed= 5
*/