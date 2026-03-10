<!-- Chunk 9 | Source: mb_manual_am5-raid_e.pdf | Est. Tokens: 291 -->
Rebuilding is the process of restoring data to a hard drive from other drives in the array. Rebuilding applies only to fault-tolerant arrays such as RAID 1 and RAID 10 arrays. To replace the old drive, make sure to use a new drive of equal or greater capacity. The procedures below assume a new drive is added to replace a failed drive to rebuild a RAID 1 array.  
While in the operating system, make sure the Chipset and RAID drivers have been installed.  
![](images/_page_7_Picture_3.jpeg)  
Step 1: Right-click on the **RAIDXpert2** icon on the desktop and then select **Run as administrator** to launch the **AMD RAIDXpert2** utility.  
![](images/_page_7_Picture_5.jpeg)  
Step 2: In the disk devices section, left-click your mouse twice on the newly-added hard drive.  
![](images/_page_7_Picture_7.jpeg)  
Step 3: On the next screen, select **Assign as Global Spare** and click **OK**.  
![](images/_page_7_Picture_9.jpeg)  
Step 4: You can check the current progress in the active volumes section on the bottom or left of the screen.  
![](images/_page_7_Picture_11.jpeg)  
Step 5: Then rebuild is complete when the **Task State** column shows "COMPLETED."