#!/bin/bash
# ===============================================================
#  Script: it_aman_printer_fix.sh
#  Created by: Mahmoud Rabia Kassem (Specialist IT Admin)
#  Version: 1.2 - Final Stable FOR FS
# ===============================================================
CURRENT_VERSION="1.2"
TOKEN="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"
USER="mahmoudkassem30"
REPO="Printers-Tools"
BRANCH="main"

VERSION_URL="https://api.github.com/repos/$USER/$REPO/contents/version.txt?ref=$BRANCH"
SCRIPT_URL="https://api.github.com/repos/$USER/$REPO/contents/printers.sh?ref=$BRANCH"

check_for_updates() {
        if ! curl -sf --connect-timeout 3 https://github.com -o /dev/null; then return; fi

    REMOTE_VERSION=$(curl -f -sL -H "Authorization: token $TOKEN" \
         -H "Accept: application/vnd.github.v3.raw" \
         --connect-timeout 5 "$VERSION_URL" | tr -d '[:space:]')

    if [ -z "$REMOTE_VERSION" ]; then
        return 
    fi

    if [[ "$REMOTE_VERSION" > "$CURRENT_VERSION" ]]; then
        zenity --question --title "تحديث متوفر New Update" \
               --text "يوجد إصدار جديد ($REMOTE_VERSION). هل تريد التحديث الآن؟" \
               --width=350 --window-icon="$SYS_ICON" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            if curl -f -sL -H "Authorization: token $TOKEN" \
                -H "Accept: application/vnd.github.v3.raw" \
                "$SCRIPT_URL" -o /tmp/printers_new.sh; then
                
                mv /tmp/printers_new.sh /usr/local/bin/it-aman
                chmod +x /usr/local/bin/it-aman
                chown root:root /usr/local/bin/it-aman
                
                zenity --info --title "Done Updated /نجاح" --text "تم التحديث إلى $REMOTE_VERSION بنجاح.\nيرجى إعادة تشغيل الأداة." 2>/dev/null
                exit 0
            else
                zenity --error --text "فشل تحميل ملف التحديث. تأكد من صلاحيات التوكن (Repo Scope)." 2>/dev/null
            fi
        fi
    fi
}
check_for_updates
handle_error() {
    local error_point="$1"
    local REAL_USER=${SUDO_USER:-$USER}
    local USER_DESKTOP="/home/$REAL_USER/Desktop"
    local LOG_FILE="$USER_DESKTOP/it_aman_error.log"
    
    echo "--- Error Report ---" >> "$LOG_FILE"
    echo "Date: $(date)" >> "$LOG_FILE"
    echo "Failed at: $error_point" >> "$LOG_FILE"
    echo "--------------------" >> "$LOG_FILE"
    
    chown $REAL_USER:$REAL_USER "$LOG_FILE"
    
    zenity --error --title "Error" --text "حدث خطأ في: $error_point\nسيتم فتح سجل الأخطاء الآن." --width=300 2>/dev/null
    sudo -u "$REAL_USER" xdg-open "$LOG_FILE" &>/dev/null
}

if [ "$EUID" -ne 0 ]; then
    zenity --error --title "Error" --text "Administrator rights required. Please use sudo." 2>/dev/null
    exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
TOOL_NAME="IT Aman - Printer Tool For FS v 1.2"
SYS_ICON="printer-error"


INFO_FILE=$(mktemp)
echo "------------------------------------------------" >> $INFO_FILE
echo "        IT Aman - Printer Support Tool          " >> $INFO_FILE
echo "------------------------------------------------" >> $INFO_FILE
echo "Developed by: Mahmoud Rabia Kassem" >> $INFO_FILE
echo "Specialist IT Admin" >> $INFO_FILE
echo "" >> $INFO_FILE
echo "This tool helps in resolving common printing issues." >> $INFO_FILE
echo "© All Rights Reserved 2026" >> $INFO_FILE

zenity --text-info --title "Welcome" --window-icon="$SYS_ICON" --filename="$INFO_FILE" --width=450 --height=260 --checkbox="Proceed / استمرار" 2>/dev/null
rm -f "$INFO_FILE"


USER_LANG=$(zenity --list --title "$TOOL_NAME" --window-icon="$SYS_ICON" --text "Select Interface Language / اختر لغة الواجهة" \
--radiolist --column "Select" --column "ID" --column "Language" \
TRUE "1" "العربية" FALSE "2" "English" --width=380 --height=250 2>/dev/null)

if [ -z "$USER_LANG" ]; then exit 0; fi

if [ "$USER_LANG" == "1" ]; then
    TXT_MENU="قائمة الخدمات المتاحة:"
    TXT_SELECT_VIDEO="اختار لينك اذا لم يعمل اللينك الاول اختار الثاني :"
    TXT_VIDEO_1="Google Drive"
    TXT_VIDEO_2="DropBox"
    TXT_O1=" معالجة حشر الورق (ارشادات)"
    TXT_O2=" فحص النظام الذكي (كشف وحل تلقائي)"
    TXT_O3=" اعاده تعريف الطابعه كبيره/حراريه (إصلاح مباشر)"
    TXT_O4=" إصلاح أوامر الطباعة (تنظيف الذاكرة العامة)"
    TXT_O5=" عرض الحالة العامة للطابعات"
    TXT_O6=" خروج"
    TXT_WAIT="جاري المعالجة، يرجى الانتظار..."
    TXT_SUCCESS="تمت العملية بنجاح ✅"
    JAM_TITLE="خطوات إزالة الورق العالق"
    JAM_MSG="⚠️ يرجى اتباع التعليمات التالية بدقة:\n\n1. أطفئ الطابعة وافصل كابل الكهرباء فوراً.\n2. افتح الأبواب المخصصة للورق.\n3. اسحب الورق العالق 'بكلتا اليدين' ببطء شديد.\n4. لا تستخدم القوة المفرطة أو أدوات حادة.\n\nاضغط OK للانتقال إلى الفيديو التوضيحي."
    REP_HDR="[ تقرير فحص IT Aman ]"
    REP_C_FX="- تم إعادة تشغيل خدمة الطباعة (CUPS)."
    REP_J_FX="- تم تنظيف مهام الطباعة العالقة."
    REP_E_FX="- تم اكتشاف طابعات معطلة وإعادة تنشيطها."
    PRINTER_LIST_MSG="اختر الطابعة التي تريد تنشيطها ومسح أوامرها:"
    ENABLE_MSG="جاري التنشيط ومسح الذاكرة..."
else
    TXT_MENU="Select a task to perform:"
    TXT_O1=" Paper Jam Guide"
    XT_SELECT_VIDEO="Choose one link; if the first link doesn't work, choose the second.:"
    TXT_VIDEO_1="Google Dirve"
    TXT_VIDEO_2="DropBox"
    TXT_O2=" Smart System Diagnostic (Auto Fix)"
    TXT_O3=" Repair Printer (Direct Enable & Clear)"
    TXT_O4=" Quick Fix Print Spooler (General)"
    TXT_O5=" View Printer Status"
    TXT_O6=" Exit"
    TXT_WAIT="Processing, please wait..."
    TXT_SUCCESS="Task completed successfully ✅"
    JAM_TITLE="Paper Jam Removal Steps"
    JAM_MSG="⚠️ Important Instructions:\n\n1. Power off printer and unplug power cable.\n2. Open the designated paper access doors.\n3. Pull the stuck paper slowly using 'both hands'.\n4. Avoid excessive force or sharp tools.\n\nClick OK for the video guide."
    REP_HDR="[ IT Aman Diagnostic Report ]"
    REP_C_FX="- Print service (CUPS) was restarted."
    REP_J_FX="- Stuck jobs have been cleared."
    REP_E_FX="- Disabled printers were re-enabled."
    PRINTER_LIST_MSG="Select printer to enable and clear:"
    ENABLE_MSG="Enabling and clearing jobs..."
fi

while true; do
    CHOICE=$(zenity --list --title "$TOOL_NAME" --window-icon="$SYS_ICON" --text "$TXT_MENU" \
    --radiolist --column "Select" --column "ID" --column "Option" \
    FALSE "1" "$TXT_O1" FALSE "2" "$TXT_O2" FALSE "3" "$TXT_O3" \
    FALSE "4" "$TXT_O4" FALSE "5" "$TXT_O5" FALSE "6" "$TXT_O6" \
    --width=600 --height=450 2>/dev/null)

    if [ -z "$CHOICE" ] || [ "$CHOICE" == "6" ]; then exit 0; fi

    case "$CHOICE" in
1)
            zenity --info --title "$JAM_TITLE" --window-icon="$SYS_ICON" --text "$JAM_MSG" --width=500 2>/dev/null

            VIDEO_CHOICE=$(zenity --list --title "$JAM_TITLE" --window-icon="$SYS_ICON" \
                --text "$TXT_SELECT_VIDEO" \
                --column "ID" --column "Video Description" \
                "1" "$TXT_VIDEO_1" \
                "2" "$TXT_VIDEO_2" \
                --width=400 --height=250 2>/dev/null)

            case "$VIDEO_CHOICE" in
                "1")
                    sudo -u "$REAL_USER" xdg-open "https://drive.google.com/file/d/1Ir08HroVj6TShF-ZOCiXvbwk8THkED1E/view?usp=drive_link" &>/dev/null &
                    ;;
                "2")
                    sudo -u "$REAL_USER" xdg-open "https://www.dropbox.com/scl/fi/pg75dydlchtpju7j65kr2/Remove-paper-jam-inside-keyocera-UK-TECH-720p-h264.mp4?rlkey=obb9ghb14yq5l19dv4fdllwfd&st=mw2bixwi&dl=0" &>/dev/null &
                    ;;
            esac
            ;;
       
        2) 
            DIAG_LOG=$(mktemp)
            (
            echo "10"; sleep 0.5
            # التأكد من تشغيل خدمة CUPS
            if ! systemctl is-active --quiet cups; then 
                systemctl restart cups; echo -e "$REP_C_FX" >> "$DIAG_LOG"
            fi
            
            echo "40"
            # تنظيف المهام العالقة
            if [ -n "$(lpstat -o)" ]; then 
                cancel -a 2>/dev/null; echo -e "$REP_J_FX" >> "$DIAG_LOG"
            fi
            
            echo "70"
            # إعادة تفعيل الطابعات المتوقفة (Disabled)
            DISABLED_PRINTERS=$(lpstat -p | grep "disabled" | awk '{print $2}')
            if [ -n "$DISABLED_PRINTERS" ]; then
                while read -r p; do
                    cupsenable "$p"; cupsaccept "$p"
                done <<< "$DISABLED_PRINTERS"
                echo -e "$REP_E_FX" >> "$DIAG_LOG"
            fi
            echo "100" ) | zenity --progress --title "$TOOL_NAME" --text "$TXT_WAIT" --auto-close 2>/dev/null
            
            # عرض التقرير النهائي
            if [ ! -s "$DIAG_LOG" ]; then
                FINAL_MSG="النظام يعمل بشكل جيد، لم يتم العثور على أخطاء برمجية."
            else
                FINAL_MSG=$(cat "$DIAG_LOG")
            fi
            
            zenity --info --title "تقرير الإصلاح" --text "<b>$REP_HDR</b>\n\n$FINAL_MSG\n\n$TXT_SUCCESS" --width=450 2>/dev/null
            rm -f "$DIAG_LOG"
            ;;
        3)
            PRINTER_LIST=$(lpstat -e)
            if [ -z "$PRINTER_LIST" ]; then
                zenity --error --text "لا توجد طابعات مضافة للنظام." 2>/dev/null
            else
                SELECTED_PRINTER=$(echo "$PRINTER_LIST" | zenity --list --title "إدارة الطابعات" --text "$PRINTER_LIST_MSG" --column "اسم الطابعة" --width=400 --height=300 2>/dev/null)
                if [ -n "$SELECTED_PRINTER" ]; then
                    (
                    echo "30"; cancel -a "$SELECTED_PRINTER" 2>/dev/null
                    echo "60"; cupsenable "$SELECTED_PRINTER" 2>/dev/null
                    echo "90"; cupsaccept "$SELECTED_PRINTER" 2>/dev/null
                    echo "100"
                    ) | zenity --progress --text "$ENABLE_MSG" --auto-close 2>/dev/null
                    zenity --info --text "$TXT_SUCCESS\nتم تفعيل الطابعة ($SELECTED_PRINTER) ومسح الأوامر بنجاح." --width=350 2>/dev/null
                fi
            fi
            ;;
        4)
            (echo "50"; systemctl stop cups; rm -rf /var/spool/cups/*; systemctl start cups; echo "100") | zenity --progress --text "$TXT_WAIT" --auto-close 2>/dev/null
            zenity --info --text "$TXT_SUCCESS" 2>/dev/null
            ;;
        5)
            STATUS=$(lpstat -p 2>/dev/null); JOBS=$(lpstat -o 2>/dev/null)
            zenity --info --text "<b>الحالة العامة:</b>\n$STATUS\n\n<b>الأوامر العالقة:</b>\n$JOBS" --width=520 2>/dev/null
            ;;
    esac
done
