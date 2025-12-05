# Windows Test Kit

Automated testing suite for the ALC1220 audio fix.

## How to Use

1. Boot into Windows
2. Right-click `RUN-TESTS.bat` → **Run as administrator**
3. Watch the automated tests run
4. Perform the manual audio tests when prompted
5. Reboot if needed
6. Test again after reboot

## What It Tests

| Test | Description |
|------|-------------|
| Realtek Device | Checks if ALC1220 is detected |
| Driver Version | Reports installed Realtek driver version |
| Registry Paths | Verifies Realtek registry locations exist |
| Registry Values | Shows before/after fix values |
| Fix Application | Applies the registry fix |
| Audio Endpoints | Lists active audio devices |

## Output

- Test results displayed in console
- Report saved to `test-report-YYYYMMDD-HHMMSS.txt`

## Manual Tests

After automated tests, you must manually verify:

1. Plug headphones into **front** panel jack
2. Plug speakers into **rear** green jack
3. Play audio
4. Confirm **both** outputs work simultaneously
