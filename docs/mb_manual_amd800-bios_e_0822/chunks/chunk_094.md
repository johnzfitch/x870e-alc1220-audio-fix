<!-- Chunk 94 | Source: mb_manual_amd800-bios_e_0822.pdf | Est. Tokens: 402 -->
Enables or disables UEFI CSM (Compatibility Support Module) to support a legacy PC boot process.  
Disabled Disables UEFI CSM and supports UEFI BIOS boot process only.  
Enabled Enables UEFI CSM.  
#### & **LAN PXE Boot Option ROM**  
Allows you to select whether to enable the legacy option ROM for the LAN controller.  
This item is configurable only when **CSM Support** is set to **Enabled**.  
#### & **Storage Boot Option Control**  
Allows you to select whether to enable the UEFI or legacy option ROM for the storage device controller.  
Disabled Disables Option ROM.  
UEFI Only Enables UEFI Option ROM only. Legacy Only Enables Legacy Option ROM only.  
This item is configurable only when **CSM Support** is set to **Enabled**.  
#### & **Other PCI Device ROM Priority**  
Allows you to select whether to enable the UEFI or Legacy option ROM for the PCI device controller other than the LAN, storage device, and graphics controllers.  
Disabled Disables Option ROM.  
UEFI Only Enables UEFI Option ROM only. Legacy Only Enables Legacy Option ROM only.  
This item is configurable only when **CSM Support** is set to **Enabled**.  
#### & **Administrator Password**  
Allows you to configure an administrator password. Press <Enter> on this item, type the password, and then press <Enter>. You will be requested to confirm the password. Type the password again and press <Enter>. You must enter the administrator password (or user password) at system startup and when entering BIOS Setup. Differing from the user password, the administrator password allows you to make changes to all BIOS settings.