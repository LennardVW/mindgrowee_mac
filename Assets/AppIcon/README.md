# MindGrowee App Icon

## Icon Design

The app icon follows macOS design guidelines with a simple, recognizable design:

**Concept**: Checkmark in a circle representing habit completion

**Sizes needed**:
- 16x16
- 32x32
- 64x64
- 128x128
- 256x256
- 512x512
- 1024x1024 (@2x)

## Creating Icons

To generate the icon set:

1. Create a 1024x1024px design in your preferred tool (Figma, Sketch, Illustrator)
2. Export at all required sizes
3. Use the following naming convention:
   - icon_16x16.png
   - icon_16x16@2x.png
   - icon_32x32.png
   - icon_32x32@2x.png
   - icon_128x128.png
   - icon_128x128@2x.png
   - icon_256x256.png
   - icon_256x256@2x.png
   - icon_512x512.png
   - icon_512x512@2x.png

4. Create .icns file:
```bash
iconutil -c icns icon.iconset
```

## Design Guidelines

- Use the accent blue (#007AFF) as primary color
- Simple checkmark symbol
- Rounded corners (macOS style)
- Clean, minimal design
- Works in both light and dark mode

## Current Status

⚠️ Placeholder - needs actual icon design
