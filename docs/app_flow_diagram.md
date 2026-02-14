# Image Resize App Flow Diagram

This diagram shows the complete workflow of the Image Resize application from start to finish.

```mermaid
flowchart TD
    Start([User Opens App]) --> SelectSource{Select Image Source}
    
    SelectSource -->|Photos Button| PhotosPicker[Open Photo Library Picker]
    SelectSource -->|Files/Drive Button| FilePicker[Open File/Cloud Picker]
    
    PhotosPicker --> macOSCheck{Platform?}
    macOSCheck -->|macOS 13+| NativePicker[Native PHPicker]
    macOSCheck -->|iOS/Android| GalleryPicker[Native Gallery Picker]
    macOSCheck -->|macOS < 13| FilePicker
    
    NativePicker --> ImagesSelected[Images Selected]
    GalleryPicker --> ImagesSelected
    FilePicker --> ImagesSelected
    
    ImagesSelected --> LoadEXIF[Load EXIF Data<br/>Auto-detect DPI]
    LoadEXIF --> PopulateFields[Populate Fields<br/>Width, Height, DPI<br/>Base Filename]
    
    PopulateFields --> ConfigDimensions[User Configures<br/>Dimensions & Options]
    
    ConfigDimensions --> SetUnit{Dimension Unit?}
    SetUnit -->|Pixels| PixelCalc[Direct Pixel Values]
    SetUnit -->|Percentage| PercentCalc[Calculate per Image<br/>% of Original]
    SetUnit -->|Inches/cm/mm| DPICalc[Calculate using DPI]
    
    PixelCalc --> ChooseSave
    PercentCalc --> ChooseSave
    DPICalc --> ChooseSave
    
    ChooseSave[Choose Save Destination] --> SaveType{Save To?}
    
    SaveType -->|Device Photos| PhotosCheck{Platform?}
    SaveType -->|Cloud/File System| SelectDir[Select Save Directory]
    
    PhotosCheck -->|iOS/Android| PhotosOK[Photos Save Enabled]
    PhotosCheck -->|macOS| PhotosBlocked[Error: Not Supported<br/>Choose Different Option]
    
    PhotosBlocked --> SaveType
    
    SelectDir --> DirSelected[Directory Selected]
    PhotosOK --> ReadyResize
    DirSelected --> ReadyResize
    
    ReadyResize[User Taps Resize] --> CheckConflicts{Files Exist?}
    
    CheckConflicts -->|Yes| ConflictDialog[Show Conflict Dialog<br/>Overwrite or Add Number?]
    CheckConflicts -->|No| ProcessLoop
    
    ConflictDialog --> UserChoice{User Choice?}
    UserChoice -->|Overwrite| ProcessLoop
    UserChoice -->|Add Number| ProcessLoop
    
    ProcessLoop[For Each Image] --> ReadImage[Read Image Bytes]
    ReadImage --> DecodeImage[Decode Image]
    DecodeImage --> CalcDims[Calculate Dimensions<br/>for THIS Image]
    CalcDims --> ResizeImage[Resize Image]
    ResizeImage --> UpdateEXIF[Update EXIF<br/>Resolution Tags]
    UpdateEXIF --> EncodeImage[Encode to JPG/PNG]
    EncodeImage --> SaveImage{Save Destination?}
    
    SaveImage -->|Photos| SavePhotos[Save to Photo Library<br/>using gal package]
    SaveImage -->|File System| SaveFile[Write to File<br/>Handle Conflicts]
    
    SavePhotos --> MoreImages{More Images?}
    SaveFile --> MoreImages
    
    MoreImages -->|Yes| ProcessLoop
    MoreImages -->|No| Success[Show Success Message]
    
    Success --> End([Done])
    
    style Start fill:#e1f5e1
    style End fill:#e1f5e1
    style PhotosBlocked fill:#ffe1e1
    style ConflictDialog fill:#fff4e1
    style Success fill:#e1f5e1
    style ProcessLoop fill:#e1e8ff
    style CalcDims fill:#ffe1f5
```

## Key Highlights

### Platform-Specific Behavior
- **macOS 13+**: Uses native PHPicker for Photos selection
- **macOS < 13**: Falls back to file picker
- **iOS/Android**: Uses native gallery picker
- **macOS Photos Save**: Blocked with error message (Flutter limitation)

### Critical Processing Steps
- **Calculate Dimensions for THIS Image** (pink): Each image gets its own dimension calculation to preserve aspect ratios
- **For Each Image** (blue): Processing loop handles multiple images individually
- **File Conflict Handling** (yellow): User chooses overwrite or add sequence number

### Color Legend
- 🟢 Green: Start/End/Success states
- 🔴 Red: Error/Blocked states
- 🟡 Yellow: User decision points
- 🔵 Blue: Processing loop
- 🟣 Pink: Key feature (per-image calculation)

