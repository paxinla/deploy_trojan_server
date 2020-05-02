.PHONY: install

INSTALLER = "run.sh"
IP = 
PASSWORD = "nopass"

install:
	find . -type f -name "*.sh" -exec chmod +x
	@$(INSTALLER) $(IP) $(PASSWORD)
