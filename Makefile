OUT_DIR	:= out

TF_A_BL1	:= $(OUT_DIR)/tf-a/fvp/debug/bl1.bin
TF_A_FIP	:= $(OUT_DIR)/tf-a/fvp/debug/fip.bin
UBOOT_BIN	:= $(OUT_DIR)/uboot/u-boot.bin

.PHONY: all tf-a u-boot run build clean

all:	build

build:	tf-a

tf-a:	u-boot hafnium
	@echo "Building TF-A + FIP"
	./scripts/build-tfa.sh

u-boot:
	@echo "Building U-Boot"
	./scripts/build-uboot.sh

hafnium:
	@echo "Building Hafnium"
	./scripts/build-hafnium.sh

ffa-acs-tests:
	@echo "Building FFA-ACS-SPs"
	./scripts/build-ff-a-acs.sh

run: 	
	@echo "Launching Arm FVP"
	./scripts/launch-fvp.sh
clean:
	rm -rf $(OUT_DIR)/*
