SDK := $(HOME)/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2
MONKEYC := $(SDK)/bin/monkeyc
MONKEYDO := $(SDK)/bin/monkeydo
SIMULATOR := $(SDK)/bin/connectiq

# DEVICE := fr955
DEVICE := vivoactive6
PROJECT := Garage
OUTPUT := bin/$(PROJECT).prg
JUNGLE := monkey.jungle
KEY := $(HOME)/.Garmin/developer_key

.PHONY: run build simulator

run: simulator build
	$(MONKEYDO) $(OUTPUT) $(DEVICE)

build:
	$(MONKEYC) \
		-f $(JUNGLE) \
		-o $(OUTPUT) \
		-y $(KEY) \
		-d $(DEVICE)

simulator:
	@if ! pgrep -x "connectiq" > /dev/null; then \
		echo "Abriendo Connect IQ Simulator..."; \
		$(SIMULATOR) >/dev/null 2>&1 & \
		sleep 2; \
	else \
		echo "Connect IQ Simulator ya está abierto"; \
	fi
