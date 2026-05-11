# --- 變數定義 ---
SIM_TOOL  = dsim
IMAGE_NAME = apb_mem_sim
TOP_MODULE = top_tb
FLIST      = apb.f
TEST_NAME  = apb_test_wr_rd
SEED       = $(shell date +%s) # 使用時間戳作為隨機種子

# --- 主要指令 ---

.PHONY: all comp run clean waves

all: comp run

# 1. 編譯階段 (Compilation)
# -genimage: 產生模擬映像檔
# -uvm 1.2: 啟用 DSim 內建的 UVM 1.2 庫
# +acc+rw: 為了看波形，開啟讀寫權限
comp:
	$(SIM_TOOL) -genimage $(IMAGE_NAME) \
				-uvm 1.2 \
				-f $(FLIST) \
				-top $(TOP_MODULE) \
				+acc+rw

# 2. 仿真階段 (Simulation)
# -image: 指定要執行的映像檔
# +UVM_TESTNAME: 指定要跑的 UVM test class
# -waves: 輸出波形檔 (預設為 dsim.vcd 或 .mti)
run:
	$(SIM_TOOL) -image $(IMAGE_NAME) \
				+UVM_TESTNAME=$(TEST_NAME) \
				-sv_seed $(SEED) \
				-waves dump.vcd

# 3. 查看波形 (以常見的 GTKWave 為例，或使用 Altair 內建工具)
waves:
	gtkwave dump.vcd &

# 4. 清理暫存檔
clean:
	rm -rf dsim_work *.log *.vcd $(IMAGE_NAME)