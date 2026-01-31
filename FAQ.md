# Frequently Asked Questions (FAQ)

## General Questions

### Q: Is MindGrowee free?
**A:** Yes! MindGrowee is completely free and open source under the MIT License.

### Q: Does MindGrowee require an internet connection?
**A:** No, MindGrowee works entirely offline. All your data is stored locally on your Mac.

### Q: Is my data private?
**A:** Absolutely! All data is stored locally using SwiftData. No data leaves your device unless you explicitly export it.

### Q: Can I sync between devices?
**A:** Not yet. MindGrowee currently stores data locally on each Mac. You can export your data as JSON and import it on another device.

## Using MindGrowee

### Q: How do I create a habit?
**A:** Click the "+" button in the Habits tab, or use the keyboard shortcut `Cmd+Shift+N`.

### Q: Do habits reset automatically?
**A:** Yes! Habits reset at midnight each day, giving you a fresh start every morning.

### Q: Can I track habits multiple times per day?
**A:** Currently, each habit can only be marked complete once per day. This is by design to maintain simplicity.

### Q: How do streaks work?
**A:** A streak counts consecutive days you've completed your habits. If you miss a day, the streak breaks (unless you use a Streak Freeze).

### Q: What are Focus Modes?
**A:** Focus Modes let you group specific habits for different contexts (e.g., "Morning Routine", "Work Day"). Only those habits will be shown.

### Q: How do I set up notifications?
**A:** Open a habit's details (click the ℹ️ icon) and set a reminder time. Make sure notifications are enabled in System Settings.

### Q: Can I change the app's appearance?
**A:** Yes! Go to Settings (Cmd+,) to toggle dark mode or choose a custom accent color.

## Data Management

### Q: How do I backup my data?
**A:** MindGrowee automatically creates daily backups. You can also manually export your data in Settings > Export.

### Q: Where is my data stored?
**A:** Your data is stored in `~/Library/Containers/com.mindgrowee.app/Data/Library/Application Support/` (or equivalent SwiftData location).

### Q: How do I restore from a backup?
**A:** Go to Settings > Import, and select your backup file.

### Q: Can I export my data?
**A:** Yes! You can export as JSON (full data), Markdown (readable), or CSV (spreadsheet).

### Q: How do I delete all my data?
**A:** Go to Settings and click "Clear All Data". This cannot be undone!

## Troubleshooting

### Q: The app won't launch. What should I do?
**A:** 
1. Make sure you're on macOS 14.0 or later
2. Try restarting your Mac
3. Check Console.app for error messages
4. Reinstall the app if necessary

### Q: Notifications aren't working. Why?
**A:**
1. Check System Settings > Notifications > MindGrowee
2. Make sure notifications are enabled
3. Verify Do Not Disturb is off
4. Restart the app

### Q: My data disappeared. Help!
**A:**
1. Check if you accidentally switched to a different focus mode
2. Look in your backups folder for automatic backups
3. Check if you have multiple user accounts on your Mac

### Q: The app is slow. How can I improve performance?
**A:**
1. Try reducing the number of habits
2. Archive old journal entries
3. Restart the app
4. Check Activity Monitor for system resources

### Q: Keyboard shortcuts aren't working.
**A:**
1. Make sure another app isn't using the same shortcut
2. Check System Settings > Keyboard > Shortcuts
3. Try restarting MindGrowee

## Contributing

### Q: How can I contribute?
**A:** See our [Contributing Guide](CONTRIBUTING.md) for details on how to report bugs, request features, or submit code.

### Q: I found a bug. Where do I report it?
**A:** Please [open an issue on GitHub](https://github.com/LennardVW/mindgrowee_mac/issues) with the bug report template.

### Q: Can I request a feature?
**A:** Yes! Open a feature request on GitHub. We can't promise to implement everything, but we read all suggestions.

## macOS Integration

### Q: Does it support Apple Silicon (M1/M2/M3)?
**A:** Yes! MindGrowee is built as a Universal app and runs natively on both Intel and Apple Silicon Macs.

### Q: Does it support macOS Sonoma widgets?
**A:** Yes! Add MindGrowee widgets to your Notification Center in macOS 14.0+.

### Q: Can I use Spotlight to find my habits?
**A:** Yes! Your habits and journal entries are indexed by Spotlight. Use Cmd+Space to search.

### Q: Does it work with Shortcuts app?
**A:** Basic Shortcuts support is planned for a future update.

## Still have questions?

If your question isn't answered here, please:
1. Check the [README](README.md) for more details
2. Search [existing issues](https://github.com/LennardVW/mindgrowee_mac/issues)
3. [Open a new issue](https://github.com/LennardVW/mindgrowee_mac/issues/new) with the "Question" template
