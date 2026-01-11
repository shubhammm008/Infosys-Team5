#!/bin/bash

echo "🔧 Adding Supabase files to Xcode project..."
echo ""

PROJECT_DIR="/Users/akshatsingh/Desktop/INFOSYS/LMTS"
cd "$PROJECT_DIR"

# List of files to add
FILES_TO_ADD=(
    "LTMS/LTMS/Services/SupabaseConfig.swift"
    "LTMS/LTMS/Services/SupabaseService.swift"
    "LTMS/LTMS/Services/SupabaseAuthService.swift"
    "LTMS/LTMS/Models/User+Supabase.swift"
    "LTMS/LTMS/Supabase-Info.plist"
)

echo "Files that need to be added to Xcode:"
echo "======================================"
for file in "${FILES_TO_ADD[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file (exists)"
    else
        echo "❌ $file (missing!)"
    fi
done

echo ""
echo "======================================"
echo "📝 INSTRUCTIONS:"
echo "======================================"
echo ""
echo "Since Xcode is now open, please do the following:"
echo ""
echo "1. In Xcode, right-click on the 'Services' folder"
echo "2. Select 'Add Files to LTMS...'"
echo "3. Navigate to: LTMS/LTMS/Services/"
echo "4. Select these 3 files:"
echo "   - SupabaseConfig.swift"
echo "   - SupabaseService.swift"
echo "   - SupabaseAuthService.swift"
echo "5. Make sure 'Add to targets: LTMS' is CHECKED ✅"
echo "6. Click 'Add'"
echo ""
echo "7. Right-click on the 'Models' folder"
echo "8. Select 'Add Files to LTMS...'"
echo "9. Navigate to: LTMS/LTMS/Models/"
echo "10. Select: User+Supabase.swift"
echo "11. Make sure 'Add to targets: LTMS' is CHECKED ✅"
echo "12. Click 'Add'"
echo ""
echo "13. Right-click on the 'LTMS' folder (main yellow folder)"
echo "14. Select 'Add Files to LTMS...'"
echo "15. Navigate to: LTMS/LTMS/"
echo "16. Select: Supabase-Info.plist"
echo "17. Make sure 'Add to targets: LTMS' is CHECKED ✅"
echo "18. Click 'Add'"
echo ""
echo "======================================"
echo "Then press Cmd+B to build!"
echo "======================================"
