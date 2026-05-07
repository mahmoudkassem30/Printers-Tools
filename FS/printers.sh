#!/bin/bash
# ===============================================================
#  Script: it_aman_printer_fix.sh
#  Created by: Mahmoud Rabia Kassem (Specialist IT Admin)
#  Version: 1.3 - Final Stable For FS
# ===============================================================
CURRENT_VERSION="1.3"
USER="mahmoudkassem30"
REPO="Printers-Tools"
BRANCH="main"

VERSION_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/FS/version.txt"
SCRIPT_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/FS/printers.sh"

check_for_updates() {
        if ! curl -sf --connect-timeout 3 https://github.com -o /dev/null; then return; fi

    REMOTE_VERSION=$(curl -f -sL \
         --connect-timeout 5 "$VERSION_URL" | tr -d '[:space:]')

    if [ -z "$REMOTE_VERSION" ]; then
        return 
    fi

    if [ "$REMOTE_VERSION" != "$CURRENT_VERSION" ] && \
       [ "$(printf '%s\n%s\n' "$CURRENT_VERSION" "$REMOTE_VERSION" | sort -V | tail -1)" = "$REMOTE_VERSION" ]; then
        refresh_sys_icon
        read _W _H < <(get_win_size medium)
        zenity --question --title "تحديث متوفر New Update" \
               --text "يوجد إصدار جديد ($REMOTE_VERSION). هل تريد التحديث الآن؟" \
               --width=$_W --window-icon="$SYS_ICON" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            if curl -f -sL \
                "$SCRIPT_URL" -o /tmp/printers_new.sh; then
                
                mv /tmp/printers_new.sh /usr/local/bin/it-aman
                chmod +x /usr/local/bin/it-aman
                chown root:root /usr/local/bin/it-aman
                
                zenity --info --title "Done Updated /نجاح" --text "تم التحديث إلى $REMOTE_VERSION بنجاح.\nيرجى إعادة تشغيل الأداة." 2>/dev/null
                exit 0
            else
                zenity --error --text "فشل تحميل ملف التحديث." 2>/dev/null
            fi
        fi
    fi
}
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


CUPS_ADMIN_USER="admin"
export CUPS_SERVER=localhost
export IPP_PORT=631


CUPS_SUDOERS_FILE="/etc/sudoers.d/it-aman-cups"
if [ ! -f "$CUPS_SUDOERS_FILE" ]; then
    cat > "$CUPS_SUDOERS_FILE" <<'EOF'
admin ALL=(ALL) NOPASSWD: /usr/sbin/lpadmin, /usr/sbin/cupsenable, /usr/sbin/cupsaccept, /usr/sbin/cancel
EOF
    chmod 0440 "$CUPS_SUDOERS_FILE"
fi
TOOL_NAME="IT Aman - Printer Tool For FS v 1.3"
SYS_ICON_NAME="it-aman-printer"
SYS_ICON_PATH=""
SYS_ICON_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/main/sources/Icons/icon-printer.png"
SYS_ICON_FILE="/usr/local/share/it-aman/icons/icon-printer.png"
SYS_ICON_THEME_FILE="/usr/share/icons/hicolor/128x128/apps/${SYS_ICON_NAME}.png"
DESKTOP_FILE="/usr/share/applications/it-aman-printer.desktop"
SCRIPT_ABS_PATH="$(readlink -f "$0" 2>/dev/null || echo "$0")"
for _ICON_CAND in \
    /usr/share/icons/hicolor/48x48/devices/printer.png \
    /usr/share/icons/Adwaita/48x48/devices/printer.png \
    /usr/share/icons/Adwaita/64x64/devices/printer.png
do
    if [ -f "$_ICON_CAND" ]; then
        SYS_ICON_PATH="$_ICON_CAND"
        break
    fi
done
SYS_ICON="${SYS_ICON_NAME}"

refresh_sys_icon() {
    if [ -s "$SYS_ICON_FILE" ]; then
        mkdir -p "$(dirname "$SYS_ICON_THEME_FILE")" >/dev/null 2>&1
        if [ ! -s "$SYS_ICON_THEME_FILE" ] || ! cmp -s "$SYS_ICON_FILE" "$SYS_ICON_THEME_FILE"; then
            cp -f "$SYS_ICON_FILE" "$SYS_ICON_THEME_FILE" >/dev/null 2>&1
            mkdir -p /usr/share/icons/hicolor/64x64/apps >/dev/null 2>&1
            cp -f "$SYS_ICON_FILE" /usr/share/icons/hicolor/64x64/apps/${SYS_ICON_NAME}.png >/dev/null 2>&1
            command -v gtk-update-icon-cache >/dev/null 2>&1 && \
                gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1
        fi
        SYS_ICON="$SYS_ICON_NAME"
    else
        SYS_ICON="${SYS_ICON_PATH:-printer}"
    fi
}

ensure_desktop_entry() {
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=IT Aman Printer Tool
Exec=${SCRIPT_ABS_PATH}
Icon=${SYS_ICON_FILE}
Terminal=false
Categories=Utility;System;
StartupWMClass=zenity
EOF
    command -v update-desktop-database >/dev/null 2>&1 && \
        update-desktop-database /usr/share/applications >/dev/null 2>&1
}

(
    if [ ! -s "$SYS_ICON_FILE" ]; then
        mkdir -p "$(dirname "$SYS_ICON_FILE")" >/dev/null 2>&1
        curl -fL --connect-timeout 8 --max-time 30 --retry 1 \
            -o "${SYS_ICON_FILE}.tmp" "$SYS_ICON_URL" >/dev/null 2>&1 \
            && mv -f "${SYS_ICON_FILE}.tmp" "$SYS_ICON_FILE"
    fi
) &
refresh_sys_icon
ensure_desktop_entry

# ── Dynamic Window Sizing ──
get_win_size() {
    local TYPE="${1:-medium}"
    local SCR_W SCR_H


    if command -v xrandr &>/dev/null; then
        read SCR_W SCR_H < <(xrandr 2>/dev/null \
            | grep -oE '[0-9]+x[0-9]+' | head -1 \
            | awk -Fx '{print $1, $2}')
    fi

    # fallback لو xrandr مش شغال
    [ -z "$SCR_W" ] && SCR_W=1920
    [ -z "$SCR_H" ] && SCR_H=1080

    local W H
    case "$TYPE" in
        small)
            W=$(( SCR_W * 28 / 100 )); H=$(( SCR_H * 28 / 100 ))
            [ "$W" -lt 320 ] && W=320;  [ "$W" -gt 480 ] && W=480
            [ "$H" -lt 180 ] && H=180;  [ "$H" -gt 300 ] && H=300
            ;;
        medium)
            W=$(( SCR_W * 35 / 100 )); H=$(( SCR_H * 38 / 100 ))
            [ "$W" -lt 420 ] && W=420;  [ "$W" -gt 600 ] && W=600
            [ "$H" -lt 260 ] && H=260;  [ "$H" -gt 420 ] && H=420
            ;;
        large)
            W=$(( SCR_W * 42 / 100 )); H=$(( SCR_H * 52 / 100 ))
            [ "$W" -lt 520 ] && W=520;  [ "$W" -gt 680 ] && W=680
            [ "$H" -lt 360 ] && H=360;  [ "$H" -gt 620 ] && H=620
            ;;
        wide)
            W=$(( SCR_W * 45 / 100 )); H=$(( SCR_H * 38 / 100 ))
            [ "$W" -lt 540 ] && W=540;  [ "$W" -gt 720 ] && W=720
            [ "$H" -lt 260 ] && H=260;  [ "$H" -gt 420 ] && H=420
            ;;
        progress)
            W=$(( SCR_W * 32 / 100 )); H=$(( SCR_H * 18 / 100 ))
            [ "$W" -lt 380 ] && W=380;  [ "$W" -gt 560 ] && W=560
            [ "$H" -lt 130 ] && H=130;  [ "$H" -gt 200 ] && H=200
            ;;
    esac
    echo "$W $H"
}

pick_thermal_size_value() {
    local OPT_LINE="$1"
    local TOKENS

    TOKENS=$(echo "$OPT_LINE" | tr ' ' '\n' | sed 's/^\*//' | cut -d'/' -f1)

    echo "$TOKENS" | grep -Ei '^Custom\.80x297mm$|^80[^0-9]*x[^0-9]*297(mm)?$|^w80h297$' | head -1 && return
    echo "$TOKENS" | grep -Ei '^Custom\.72x297mm$|^72[^0-9]*x[^0-9]*297(mm)?$|^w72h297$' | head -1 && return
    echo "$TOKENS" | grep -Ei '80[^0-9]*x[^0-9]*297|297[^0-9]*x[^0-9]*80|72[^0-9]*x[^0-9]*297|297[^0-9]*x[^0-9]*72' | head -1
}

extract_cups_tokens() {
    local OPT_LINE="$1"
    echo "$OPT_LINE" \
        | sed 's/^[^:]*://g' \
        | tr ' ' '\n' \
        | sed 's/^\*//' \
        | cut -d'/' -f1 \
        | sed '/^$/d'
}

resolve_thermal_size_from_tokens() {
    local TOKENS="$1"
    local TOKENS_NO_CUSTOM
    local V

    TOKENS_NO_CUSTOM=$(echo "$TOKENS" | grep -E -i -v 'custom')

    for V in 80x297mm 80x297 80mmx297mm 80mmx297 w80h297 72x297mm 72x297 72mmx297mm 72mmx297 w72h297; do
        echo "$TOKENS_NO_CUSTOM" | grep -E -i "^${V}$" | head -1 && return
    done
    echo "$TOKENS_NO_CUSTOM" | grep -E -i '80[^0-9]*x[^0-9]*297|297[^0-9]*x[^0-9]*80' | head -1 && return
    echo "$TOKENS_NO_CUSTOM" | grep -E -i '72[^0-9]*x[^0-9]*297|297[^0-9]*x[^0-9]*72' | head -1
}

resolve_forced_custom_size_from_tokens() {
    local TOKENS="$1"
    local TOKENS_CUSTOM

    TOKENS_CUSTOM=$(echo "$TOKENS" | grep -E -i 'custom')

    echo "$TOKENS_CUSTOM" | grep -E -i '^Custom\.72x297(mm)?$|^Custom72x297(mm)?$' | head -1 && return
    echo "$TOKENS_CUSTOM" | grep -E -i '^Custom\.72\.0x297\.0(mm)?$|^Custom72\.0x297\.0(mm)?$' | head -1 && return
    echo "$TOKENS_CUSTOM" | grep -E -i '72[^0-9]*x[^0-9]*297|297[^0-9]*x[^0-9]*72' | head -1 && return
    echo "Custom.72x297mm"
}

set_thermal_defaults() {
    local PRN="$1"
    local OPTS CUT_LINE CUT_VAL

    OPTS=$(sudo -u admin /usr/bin/lpoptions -p "$PRN" -l 2>/dev/null)
    [ -z "$OPTS" ] && return

    CUT_LINE=$(echo "$OPTS" | grep -i '^CutType[/:]' | head -1)
    CUT_VAL=$(echo "$CUT_LINE" \
        | tr ' ' '\n' \
        | sed 's/^\*//' \
        | cut -d'/' -f1 \
        | grep -Ei '^FullCut$|^Full$|^Cut$' \
        | head -1)

    if [ -n "$CUT_VAL" ]; then
        sudo -u admin /usr/bin/lpoptions -p "$PRN" -o "CutType=$CUT_VAL" 2>/dev/null
        sudo -u admin /usr/sbin/lpadmin -p "$PRN" -o "CutType=$CUT_VAL" 2>/dev/null
    fi
}

check_for_updates


INFO_FILE=$(mktemp)
echo "------------------------------------------------" >> $INFO_FILE
echo "        IT Aman - Printer Support Tool For FS       " >> $INFO_FILE
echo "------------------------------------------------" >> $INFO_FILE
echo "Developed by: Mahmoud Rabia Kassem" >> $INFO_FILE
echo "Specialist IT Admin" >> $INFO_FILE
echo "" >> $INFO_FILE
echo "This tool helps in resolving common printing issues." >> $INFO_FILE
echo "© All Rights Reserved 2026" >> $INFO_FILE

refresh_sys_icon
read _W _H < <(get_win_size medium)
zenity --text-info --title "Welcome" --window-icon="$SYS_ICON" --filename="$INFO_FILE" --width=$_W --height=$_H --checkbox="Proceed / استمرار" 2>/dev/null
rm -f "$INFO_FILE"

# ── النصوص العربية الثابتة ──
TXT_MENU="قائمة الخدمات المتاحة:"
TXT_O1=" معالجة حشر الورق (ارشادات)"
TXT_O2=" فحص النظام الذكي (كشف وحل تلقائي)"
TXT_O3=" إدارة الطابعات (إضافة / حذف)"
TXT_O4=" إدارة الطابعة الحرارية (إضافة / حذف)"
TXT_O5=" إصلاح أوامر الطباعة (تنظيف الذاكرة العامة)"
TXT_O6=" خروج"
TXT_WAIT="جاري المعالجة، يرجى الانتظار..."
TXT_SUCCESS="تمت العملية بنجاح ✅"
JAM_TITLE="خطوات إزالة الورق العالق"
JAM_MSG="⚠️ يرجى اتباع التعليمات التالية بدقة:\n\n1. أطفئ الطابعة وافصل كابل الكهرباء فوراً.\n2. افتح الأبواب المخصصة للورق.\n3. اسحب الورق العالق 'بكلتا اليدين' ببطء شديد.\n4. لا تستخدم القوة المفرطة أو أدوات حادة.\n\n📷 بعد الضغط على OK سيتم عرض صورة توضيحية لطريقة الإزالة."
REP_HDR="[ تقرير فحص IT Aman ]"
REP_C_FX="- تم إعادة تشغيل خدمة الطباعة (CUPS)."
REP_J_FX="- تم تنظيف مهام الطباعة العالقة."
REP_E_FX="- تم اكتشاف طابعات معطلة وإعادة تنشيطها."
PRINTER_LIST_MSG="اختر الطابعة التي تريد تنشيطها ومسح أوامرها:"
ENABLE_MSG="جاري التنشيط ومسح الذاكرة..."

while true; do
    refresh_sys_icon
    read _W _H < <(get_win_size large)
    CHOICE=$(zenity --list --title "$TOOL_NAME" --window-icon="$SYS_ICON" --text "$TXT_MENU" \
    --radiolist --column "Select" --column "ID" --column "Option" \
    FALSE "1" "$TXT_O1" FALSE "2" "$TXT_O2" FALSE "3" "$TXT_O3" \
    FALSE "4" "$TXT_O4" \
    FALSE "5" "$TXT_O5" FALSE "6" "$TXT_O6" \
    --width=$_W --height=$_H 2>/dev/null)

    if [ -z "$CHOICE" ] || [ "$CHOICE" == "6" ]; then exit 0; fi

    case "$CHOICE" in
        1)
            read _W _H < <(get_win_size medium)
            zenity --info --title "$JAM_TITLE" --window-icon="$SYS_ICON" --text "$JAM_MSG" --width=$_W 2>/dev/null

            # فتح الصورة التوضيحية مباشرة
            JAM_IMG_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/pic/paperjam.png"
            JAM_IMG_TMP="/tmp/ita_paperjam.png"
            curl -fL --connect-timeout 10 --max-time 30 \
                -o "$JAM_IMG_TMP" "$JAM_IMG_URL" 2>/dev/null
            if [ -s "$JAM_IMG_TMP" ]; then
                if command -v eog &>/dev/null; then
                    sudo -u "$REAL_USER" eog "$JAM_IMG_TMP" &>/dev/null &
                elif command -v display &>/dev/null; then
                    sudo -u "$REAL_USER" display "$JAM_IMG_TMP" &>/dev/null &
                else
                    sudo -u "$REAL_USER" xdg-open "$JAM_IMG_TMP" &>/dev/null &
                fi
            else
                sudo -u "$REAL_USER" xdg-open "$JAM_IMG_URL" &>/dev/null &
            fi
            ;;

        2)
            # ── [DIAG] Section 1: Pre-Check — Verify printers are registered ──
            DIAG_LOG=$(mktemp)
            ALL_PRINTERS_DIAG=$(lpstat -e 2>/dev/null)

            if [ -z "$ALL_PRINTERS_DIAG" ]; then
                # No printers found — abort with clear message
                read _W _H < <(get_win_size medium)
                zenity --warning \
                    --title "تشخيص النظام" \
                    --window-icon="$SYS_ICON" \
                    --text "⚠️ لم يتم العثور على أي طابعات مضافة في النظام.\n\nالنظام لا يستطيع رؤية أي طابعة حالياً.\n\nيرجى التأكد من:\n• إضافة الطابعة أولاً من قائمة (إدارة الطابعات)\n• تشغيل الطابعة والتحقق من الاتصال بالشبكة\n• تفعيل خدمة CUPS" \
                    --width=$_W 2>/dev/null
                rm -f "$DIAG_LOG"
                continue
            fi

            # ── [DIAG] Section 2: Network reachability check ──
            UNREACHABLE_LIST=""
            while read -r PNAME; do
                [ -z "$PNAME" ] && continue
                PURI=$(lpstat -v "$PNAME" 2>/dev/null | awk '{print $NF}')
                PRINTER_IP=$(echo "$PURI" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                if [ -n "$PRINTER_IP" ]; then
                    if ! timeout 2 bash -c "echo >/dev/tcp/$PRINTER_IP/9100" 2>/dev/null && \
                       ! timeout 2 bash -c "echo >/dev/tcp/$PRINTER_IP/631" 2>/dev/null; then
                        UNREACHABLE_LIST="$UNREACHABLE_LIST\n• $PNAME ($PRINTER_IP) — غير متاح على الشبكة"
                    fi
                fi
            done <<< "$ALL_PRINTERS_DIAG"

            if [ -n "$UNREACHABLE_LIST" ]; then
                read _W _H < <(get_win_size medium)
                zenity --warning \
                    --title "تشخيص النظام" \
                    --window-icon="$SYS_ICON" \
                    --text "⚠️ الطابعات التالية غير متاحة على الشبكة حالياً:\n$UNREACHABLE_LIST\n\nيرجى التحقق من:\n• تشغيل الطابعة\n• الاتصال بنفس الشبكة\n• إعدادات IP للطابعة" \
                    --width=$_W 2>/dev/null
            fi

            # ── [DIAG] Section 3: CUPS service check and restart if needed ──
            (
            echo "10"; sleep 0.5
            if ! systemctl is-active --quiet cups; then
                systemctl restart cups
                echo -e "$REP_C_FX" >> "$DIAG_LOG"
            fi

            # ── [DIAG] Section 4: Clear stuck print jobs ──
            echo "40"
            if [ -n "$(lpstat -o 2>/dev/null)" ]; then
                sudo -u admin /usr/sbin/cancel -a 2>/dev/null
                echo -e "$REP_J_FX" >> "$DIAG_LOG"
            fi

            # ── [DIAG] Section 5: Re-enable disabled printers ──
            echo "70"
            DISABLED_PRINTERS=$(lpstat -p 2>/dev/null | grep "disabled" | awk '{print $2}')
            if [ -n "$DISABLED_PRINTERS" ]; then
                while read -r p; do
                    sudo -u admin /usr/sbin/cupsenable "$p"
                    sudo -u admin /usr/sbin/cupsaccept "$p"
                done <<< "$DISABLED_PRINTERS"
                echo -e "$REP_E_FX" >> "$DIAG_LOG"
            fi
            echo "100"
            ) | zenity --progress --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                --text "$TXT_WAIT" --auto-close 2>/dev/null

            # ── [DIAG] Section 6: Show final report ──
            if [ ! -s "$DIAG_LOG" ]; then
                FINAL_MSG="النظام يعمل بشكل جيد، لم يتم العثور على أخطاء برمجية."
            else
                FINAL_MSG=$(cat "$DIAG_LOG")
            fi
            read _W _H < <(get_win_size medium)
            zenity --info --title "تقرير الإصلاح" --window-icon="$SYS_ICON" \
                --text "<b>$REP_HDR</b>\n\n$FINAL_MSG\n\n$TXT_SUCCESS" --width=$_W 2>/dev/null
            rm -f "$DIAG_LOG"
            ;;

          
        3)
            read _W _H < <(get_win_size medium)
            MGMT_CHOICE=$(zenity --list \
                --title "$TOOL_NAME" \
                --window-icon="$SYS_ICON" \
                --text "إدارة الطابعات / Printer Management:" \
                --radiolist --column "" --column "ID" --column "Action" \
                TRUE  "add"    "🖨️  إضافة طابعة جديدة / Add New Printer" \
                FALSE "remove" "🗑️  حذف طابعة / Remove Printer" \
                --width=$_W --height=$_H 2>/dev/null)

            [ -z "$MGMT_CHOICE" ] && continue

          
            if [ "$MGMT_CHOICE" == "add" ]; then

                SCAN_LOG="/tmp/ita_scan.log"
                FOUND_FILE="/tmp/ita_found.txt"
                PROG_FILE="/tmp/ita_scan_prog.txt"
                rm -f "$FOUND_FILE" "$SCAN_LOG" "$PROG_FILE"

                
                (
                    echo "5" > "$PROG_FILE"
                    echo "# 🔍 جاري اكتشاف الشبكة..." >> "$PROG_FILE"

                  
                    LOCAL_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oE 'src [0-9.]+' | awk '{print $2}')
                    SUBNET=$(echo "$LOCAL_IP" | cut -d. -f1-3)

                    echo "# 🌐 الشبكة / Network: $SUBNET.0/24" >> "$PROG_FILE"
                    echo "الشبكة: $SUBNET.0/24" >> "$SCAN_LOG"

                 
                    echo "10" > "$PROG_FILE"
                    echo "# 🔍 فحص CUPS backends..." >> "$PROG_FILE"

                    timeout 15 sudo -u admin lpinfo -v 2>/dev/null \
                        | awk '{print $2}' \
                        | grep -iE '^(ipp|ipps|lpd|socket)://' \
                        | grep -viE 'everywhere|driverless|localhost|127\.0\.0' \
                        > /tmp/ita_lpinfo_uris.txt

                    
                    echo "20" > "$PROG_FILE"
                    echo "# 🔍 فحص الشبكة على ports 631 و 9100..." >> "$PROG_FILE"

                    if [ -n "$SUBNET" ]; then
                        for i in $(seq 1 254); do
                            HOST="$SUBNET.$i"
                            (
                                if timeout 1 bash -c "echo >/dev/tcp/$HOST/631" 2>/dev/null || \
                                   timeout 1 bash -c "echo >/dev/tcp/$HOST/9100" 2>/dev/null; then
                                    echo "ipp://$HOST/ipp/print" >> /tmp/ita_scan_uris.txt
                                fi
                            ) &
                        done
                        wait
                    fi

                    echo "45" > "$PROG_FILE"
                    echo "# 🔍 جمع النتائج..." >> "$PROG_FILE"

                    
                    if command -v avahi-browse &>/dev/null; then
                        echo "# 🔍 mDNS scan..." >> "$PROG_FILE"
                        timeout 8 avahi-browse -t -r _ipp._tcp 2>/dev/null \
                            | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
                            | sort -u \
                            | while read -r IP; do
                                echo "ipp://$IP/ipp/print" >> /tmp/ita_scan_uris.txt
                            done
                    fi

                    cat /tmp/ita_lpinfo_uris.txt /tmp/ita_scan_uris.txt 2>/dev/null \
                        | sort -u \
                        | grep -viE 'localhost|127\.0\.0' \
                        > /tmp/ita_uris.txt
                    rm -f /tmp/ita_lpinfo_uris.txt /tmp/ita_scan_uris.txt

                    TOTAL=$(wc -l < /tmp/ita_uris.txt 2>/dev/null || echo 0)
                    echo "اكتشف $TOTAL طابعة محتملة" >> "$SCAN_LOG"

                    echo "50" > "$PROG_FILE"
                    echo "# 🖨️ جاري التعرف على الطابعات ($TOTAL)..." >> "$PROG_FILE"

                    COUNT=0
                    while read -r URI; do
                        [ -z "$URI" ] && continue
                        COUNT=$((COUNT + 1))

                        PRINTER_IP=$(echo "$URI" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                        [ -z "$PRINTER_IP" ] && continue

                      
                        REAL_MODEL=""


                        WEB_PAGE=$(curl -sf --connect-timeout 3 \
                            -A "Mozilla/5.0" \
                            "http://$PRINTER_IP/" 2>/dev/null)

                        if [ -n "$WEB_PAGE" ]; then
                            REAL_MODEL=$(echo "$WEB_PAGE" \
                                | grep -ioE 'Model\s*:\s*[a-zA-Z0-9][a-zA-Z0-9\- ]{2,40}' \
                                | head -1 \
                                | sed 's/Model\s*:\s*//I' \
                                | xargs)

                            if [ -z "$REAL_MODEL" ]; then
                                REAL_MODEL=$(echo "$WEB_PAGE" \
                                    | grep -ioE '<title>[^<]{3,60}</title>' \
                                    | sed 's/<[^>]*>//g' \
                                    | grep -ioE '[a-zA-Z0-9][a-zA-Z0-9\- ]{4,40}' \
                                    | grep -iv 'home\|login\|welcome\|index\|web\|page' \
                                    | head -1 | xargs)
                            fi
                        fi


                        if [ -z "$REAL_MODEL" ]; then
                            for TRY_PATH in \
                                "/general/information.html" \
                                "/info/overview.html" \
                                "/web/guest/en/websys/webArch/mainFrame.cgi" \
                                "/cgi-bin/dynamic/config/status.html" \
                                "/status.cgi"
                            do
                                TRY_PAGE=$(curl -sf --connect-timeout 2 \
                                    -A "Mozilla/5.0" \
                                    "http://$PRINTER_IP${TRY_PATH}" 2>/dev/null)
                                if [ -n "$TRY_PAGE" ]; then
                                    REAL_MODEL=$(echo "$TRY_PAGE" \
                                        | grep -ioE 'Model\s*[:\-]?\s*[a-zA-Z0-9][a-zA-Z0-9\- ]{2,40}' \
                                        | head -1 \
                                        | sed 's/Model\s*[:\-]\s*//I' \
                                        | xargs)
                                    [ -n "$REAL_MODEL" ] && break
                                fi
                            done
                        fi


                        if [ -z "$REAL_MODEL" ] && command -v ipptool &>/dev/null; then
                            RAW_MODEL=$(timeout 5 ipptool -t "$URI" \
                                /usr/share/cups/ipptool/get-printer-attributes.test 2>/dev/null \
                                | grep -i 'printer-make-and-model' \
                                | grep -v 'REQUIRED\|STATUS\|EXPECT' \
                                | tail -1 \
                                | sed 's/.*= //;s/["\r]//g' \
                                | xargs)
                            REAL_MODEL=$(echo "$RAW_MODEL" \
                                | sed 's/KYOCERA Document Solutions Inc\.//gI' \
                                | sed 's/[Cc]orporation\b//g' \
                                | sed 's/\bInc\.\?//g' \
                                | xargs)
                        fi

                        # Fallback
                        [ -z "$REAL_MODEL" ] && REAL_MODEL="Printer @ $PRINTER_IP"


                        [ "$TOTAL" -gt 0 ] && PROG=$(( 50 + (COUNT * 45 / TOTAL) )) || PROG=80
                        echo "$PROG" > "$PROG_FILE"
                        echo "# 🖨️ ($COUNT/$TOTAL) $REAL_MODEL" >> "$PROG_FILE"
                        echo "$URI||$REAL_MODEL||$PRINTER_IP" >> "$FOUND_FILE"

                    done < /tmp/ita_uris.txt
                    rm -f /tmp/ita_uris.txt

                    echo "100" > "$PROG_FILE"
                    echo "# ✅ اكتمل البحث" >> "$PROG_FILE"
                    echo "DONE" >> "$PROG_FILE"

                ) &
                BG_PID=$!


                read _PW _PH < <(get_win_size progress)
                (
                    LAST_VAL=5
                    while kill -0 "$BG_PID" 2>/dev/null; do
                        if [ -f "$PROG_FILE" ]; then
                            NEW_VAL=$(grep '^[0-9]' "$PROG_FILE" | tail -1)
                            NEW_MSG=$(grep '^#' "$PROG_FILE" | tail -1)
                            if [ -n "$NEW_VAL" ] && [ "$NEW_VAL" != "$LAST_VAL" ]; then
                                echo "$NEW_VAL"
                                LAST_VAL="$NEW_VAL"
                            fi
                            [ -n "$NEW_MSG" ] && echo "$NEW_MSG"
                        fi
                        sleep 1
                    done
                    echo "100"
                    echo "# ✅ اكتمل / Done"
                ) | zenity --progress \
                    --title "$TOOL_NAME" \
                    --window-icon="$SYS_ICON" \
                    --text "🔍 جاري البحث عن الطابعات على الشبكة..." \
                    --width=$_PW --height=$_PH \
                    --no-cancel \
                    2>/dev/null

                wait "$BG_PID"
                rm -f "$PROG_FILE"


                DISCOVERED_LIST=""
                [ -f "$FOUND_FILE" ] && DISCOVERED_LIST=$(cat "$FOUND_FILE")
                rm -f "$FOUND_FILE"

                if [ -z "$DISCOVERED_LIST" ]; then
                    read _W _H < <(get_win_size medium)
                    zenity --warning \
                        --title "$TOOL_NAME" \
                        --window-icon="$SYS_ICON" \
                        --text "⚠️ لم يتم العثور على طابعات شبكة.\n\nتأكد من:\n• تشغيل الطابعة\n• الاتصال بنفس الشبكة\n• تفعيل خدمة CUPS\n\nLog: $SCAN_LOG" \
                        --width=$_W 2>/dev/null
                    continue
                fi


                ZENITY_ARGS=()
                while IFS='||' read -r URI MODEL IP; do
                    [ -z "$URI" ] && continue
                    ZENITY_ARGS+=("$URI" "$MODEL" "$IP")
                done <<< "$DISCOVERED_LIST"

                SELECTED_URI=$(zenity --list \
                    --title "$TOOL_NAME" \
                    --window-icon="$SYS_ICON" \
                    --text "🖨️ اختر الطابعة لإضافتها:" \
                    --column "URI" --column "الموديل / Model" --column "IP Address" \
                    --hide-column=1 --print-column=1 \
                    "${ZENITY_ARGS[@]}" \
                    --width=$_W --height=$_H 2>/dev/null)

                [ -z "$SELECTED_URI" ] && continue


                SELECTED_LINE=$(echo "$DISCOVERED_LIST" | grep "^${SELECTED_URI}||")
                SELECTED_MODEL=$(echo "$SELECTED_LINE" | awk -F'\\|\\|' '{print $2}')
                SELECTED_IP=$(echo "$SELECTED_LINE" | awk -F'\\|\\|' '{print $3}')
                [ -z "$SELECTED_MODEL" ] && SELECTED_MODEL="Printer"


                PRINTER_NAME="printer-FS"



                LPD_URI="lpd://$SELECTED_IP/queue"


                PPD_MODEL=$(lpinfo -m 2>/dev/null \
                    | grep -i "ECOSYS M3550idn" \
                    | grep -i "KPDL" \
                    | head -1 | awk '{print $1}')

                if [ -z "$PPD_MODEL" ]; then
                    PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "M3550idn" \
                        | head -1 | awk '{print $1}')
                fi

                if [ -z "$PPD_MODEL" ]; then
                    PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "ECOSYS" \
                        | head -1 | awk '{print $1}')
                fi

                [ -z "$PPD_MODEL" ] && PPD_MODEL="drv:///sample.drv/generic.ppd"


                if [ "$PPD_MODEL" == "drv:///sample.drv/generic.ppd" ]; then

                    KYO_DEB_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/Drivers/kyodialog_9.3-0_amd64.deb"
                    KYO_DEB_FILE="/tmp/kyodialog_9.3-0_amd64.deb"
                    KYO_LOG="/tmp/ita_kyocera.log"
                    PROG_FILE="/tmp/ita_kyo_prog.txt"


                    echo "3"  > "$PROG_FILE"
                    echo "# 🔍 جاري التحقق من التعريفات..." >> "$PROG_FILE"


                    (
                        echo "$(date): بدء التحميل" > "$KYO_LOG"

                        echo "8"  > "$PROG_FILE"; echo "# 📥 جاري تحميل Kyocera Package..." >> "$PROG_FILE"

                        curl -fL \
                            --connect-timeout 20 \
                            --max-time 120 \
                            --retry 2 \
                            -o "$KYO_DEB_FILE" \
                            "$KYO_DEB_URL" 2>>"$KYO_LOG"

                        if [ $? -ne 0 ] || [ ! -s "$KYO_DEB_FILE" ]; then
                            echo "$(date): فشل التحميل" >> "$KYO_LOG"
                            echo "FAIL" > "$PROG_FILE"
                        else
                            echo "$(date): اكتمل التحميل — $(du -sh "$KYO_DEB_FILE" | cut -f1)" >> "$KYO_LOG"
                            echo "55" > "$PROG_FILE"; echo "# ⚙️ جاري التثبيت..." >> "$PROG_FILE"


                            DEBIAN_FRONTEND=noninteractive dpkg -i "$KYO_DEB_FILE" >>"$KYO_LOG" 2>&1


                            apt-get install -f -y >>"$KYO_LOG" 2>&1

                            echo "$(date): اكتمل dpkg" >> "$KYO_LOG"
                            rm -f "$KYO_DEB_FILE"

                            echo "80" > "$PROG_FILE"; echo "# 🔄 إعادة تشغيل CUPS..." >> "$PROG_FILE"
                            systemctl restart cups >>"$KYO_LOG" 2>&1
                            sleep 3

                            echo "100" > "$PROG_FILE"; echo "# ✅ اكتمل التثبيت" >> "$PROG_FILE"
                            echo "DONE" >> "$PROG_FILE"
                        fi

                    ) &
                    BG_PID=$!


                    read _PW _PH < <(get_win_size progress)
                    (
                        LAST_VAL=3
                        while kill -0 "$BG_PID" 2>/dev/null; do
                            if [ -f "$PROG_FILE" ]; then
                                NEW_VAL=$(grep '^[0-9]' "$PROG_FILE" | tail -1)
                                NEW_MSG=$(grep '^#' "$PROG_FILE" | tail -1)

                                if [ -n "$NEW_VAL" ] && [ "$NEW_VAL" != "$LAST_VAL" ]; then
                                    echo "$NEW_VAL"
                                    LAST_VAL="$NEW_VAL"
                                fi
                                [ -n "$NEW_MSG" ] && echo "$NEW_MSG"

                                grep -q "^FAIL" "$PROG_FILE" 2>/dev/null && break
                            fi
                            sleep 1
                        done
                        echo "100"
                        echo "# ✅ اكتمل / Done"
                    ) | zenity --progress \
                        --title "$TOOL_NAME" \
                        --window-icon="$SYS_ICON" \
                        --text "📦 Kyocera Printing Package\n\n📥 جاري التحميل والتثبيت تلقائياً..." \
                        --width=$_PW --height=$_PH \
                        --no-cancel \
                        2>/dev/null

                    wait "$BG_PID"
                    rm -f "$PROG_FILE"


                    PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "ECOSYS M3550idn" \
                        | grep -i "KPDL" \
                        | head -1 | awk '{print $1}')

                    [ -z "$PPD_MODEL" ] && PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "M3550idn" \
                        | head -1 | awk '{print $1}')

                    [ -z "$PPD_MODEL" ] && PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "ECOSYS" \
                        | head -1 | awk '{print $1}')

                    [ -z "$PPD_MODEL" ] && PPD_MODEL=$(lpinfo -m 2>/dev/null \
                        | grep -i "Kyocera" \
                        | grep -i "KPDL" \
                        | head -1 | awk '{print $1}')

                    if [ -z "$PPD_MODEL" ]; then
                        PPD_MODEL="drv:///sample.drv/generic.ppd"
                        zenity --warning \
                            --title "$TOOL_NAME" \
                            --window-icon="$SYS_ICON" \
                            --text "⚠️ لم يتم العثور على تعريف Kyocera بعد التثبيت.\n\nسيتم استخدام Generic.\n\nLog: $KYO_LOG" \
                            --width=$_W 2>/dev/null
                    fi
                fi


                read _PW _PH < <(get_win_size progress)
                (
                    echo "10"

                    lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$" \
                        && sudo -u admin /usr/sbin/lpadmin -x "$PRINTER_NAME" 2>/dev/null
                    echo "30"
                    sudo -u admin /usr/sbin/lpadmin \
                        -p "$PRINTER_NAME" -E \
                        -v "$LPD_URI" \
                        -m "$PPD_MODEL" \
                        -D "$SELECTED_MODEL" \
                        -L "Network - $SELECTED_IP" \
                        2>/tmp/ita_err
                    echo "75"
                    sudo -u admin /usr/sbin/cupsenable "$PRINTER_NAME" 2>/dev/null
                    sudo -u admin /usr/sbin/cupsaccept "$PRINTER_NAME" 2>/dev/null
                    echo "85"


                    PAPERFEED_KEY=$(sudo -u admin /usr/bin/lpoptions \
                        -p "$PRINTER_NAME" -l 2>/dev/null \
                        | grep -i 'paper.*feed\|feed.*paper\|InputSlot\|MediaSource' \
                        | head -1 \
                        | cut -d'/' -f1 | xargs)


                    if [ -z "$PAPERFEED_KEY" ]; then
                        for TRY_KEY in InputSlot MediaSource PaperFeed KCFeeder; do
                            CHECK=$(sudo -u admin /usr/bin/lpoptions \
                                -p "$PRINTER_NAME" -l 2>/dev/null \
                                | grep -i "^$TRY_KEY" | head -1)
                            if [ -n "$CHECK" ]; then
                                PAPERFEED_KEY="$TRY_KEY"
                                break
                            fi
                        done
                    fi


                    PAPERFEED_VAL=""
                    if [ -n "$PAPERFEED_KEY" ]; then
                        PAPERFEED_VAL=$(sudo -u admin /usr/bin/lpoptions \
                            -p "$PRINTER_NAME" -l 2>/dev/null \
                            | grep -i "^$PAPERFEED_KEY" \
                            | grep -ioE '\bOne\b|\bCassette1\b|\bTray1\b|\bUpper\b' \
                            | head -1)
                        [ -z "$PAPERFEED_VAL" ] && PAPERFEED_VAL="One"
                    fi


                    if [ -n "$PAPERFEED_KEY" ] && [ -n "$PAPERFEED_VAL" ]; then
                        sudo -u admin /usr/bin/lpoptions \
                            -p "$PRINTER_NAME" \
                            -o "${PAPERFEED_KEY}=${PAPERFEED_VAL}" \
                            -o Duplex=None \
                            2>/dev/null
                        sudo -u admin /usr/sbin/lpadmin \
                            -p "$PRINTER_NAME" \
                            -o "${PAPERFEED_KEY}=${PAPERFEED_VAL}" \
                            -o Duplex=None \
                            2>/dev/null
                    else
                        sudo -u admin /usr/bin/lpoptions \
                            -p "$PRINTER_NAME" \
                            -o Duplex=None \
                            2>/dev/null
                    fi
                    echo "100"
                ) | zenity --progress \
                    --title "$TOOL_NAME" \
                    --window-icon="$SYS_ICON" \
                    --text "⚙️ جاري تثبيت الطابعة..." \
                    --auto-close --width=$_PW --height=$_PH 2>/dev/null

                read _IW _IH < <(get_win_size medium)
                if lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$"; then
                    zenity --info \
                        --title "نجاح / Success" \
                        --window-icon="$SYS_ICON" \
                        --text "✅ تمت الإضافة بنجاح!\n\n🖨️ الاسم:\n    $PRINTER_NAME\n\n📡 الموديل:\n    $SELECTED_MODEL\n\n🌐 IP: $SELECTED_IP\n\n🔌 Protocol: LPD\n\n🔧 Driver: $PPD_MODEL\n\n📄 Paper Feeder: One\n🔁 Duplex: Off" \
                        --width=$_IW 2>/dev/null
                else
                    ERR_MSG=$(cat /tmp/ita_err 2>/dev/null | head -5)
                    zenity --error \
                        --title "خطأ / Error" \
                        --window-icon="$SYS_ICON" \
                        --text "❌ فشلت إضافة الطابعة.\n\n$ERR_MSG" \
                        --width=$_IW 2>/dev/null
                fi
                rm -f /tmp/ita_err


            elif [ "$MGMT_CHOICE" == "remove" ]; then

                ALL_PRINTERS=$(lpstat -e 2>/dev/null)
                if [ -z "$ALL_PRINTERS" ]; then
                    zenity --warning \
                        --title "$TOOL_NAME" \
                        --window-icon="$SYS_ICON" \
                        --text "⚠️ لا توجد طابعات مضافة في النظام." \
                    --width=$_W 2>/dev/null
                    continue
                fi

                ZENITY_ARGS=()
                while read -r PNAME; do
                    [ -z "$PNAME" ] && continue
                    URI=$(lpstat -v "$PNAME" 2>/dev/null | awk '{print $NF}')
                    if echo "$URI" | grep -qiE 'ipp|lpd|socket|http|smb'; then
                        PTYPE="🌐 شبكة / Network"
                    elif echo "$URI" | grep -qiE 'usb|direct|parallel'; then
                        PTYPE="🔌 USB / حرارية"
                    else
                        PTYPE="❓ أخرى"
                    fi
                    ZENITY_ARGS+=("$PNAME" "$PTYPE" "$URI")
                done <<< "$ALL_PRINTERS"

                SELECTED=$(zenity --list \
                    --title "$TOOL_NAME" \
                    --window-icon="$SYS_ICON" \
                    --text "🗑️ اختر الطابعة للحذف:" \
                    --column "الاسم / Name" \
                    --column "النوع / Type" \
                    --column "العنوان / URI" \
                    --print-column=1 \
                    "${ZENITY_ARGS[@]}" \
                    --width=$_W --height=$_H 2>/dev/null)

                [ -z "$SELECTED" ] && continue

                zenity --question \
                    --title "تأكيد / Confirm" \
                    --window-icon="$SYS_ICON" \
                    --text "⚠️ هل أنت متأكد من حذف:\n\n🖨️  $SELECTED" \
                    --ok-label="نعم، احذف / Yes, Remove" \
                    --cancel-label="إلغاء / Cancel" \
                    --width=$_W 2>/dev/null

                [ $? -ne 0 ] && continue

                read _PW _PH < <(get_win_size progress)
                (
                    echo "20"
                    sudo -u admin /usr/sbin/cancel -a "$SELECTED" 2>/dev/null
                    cancel -a "$SELECTED" 2>/dev/null
                    echo "50"
                    sudo -u admin /usr/sbin/cupsdisable "$SELECTED" 2>/dev/null
                    sleep 1
                    echo "70"
                    sudo -u admin /usr/sbin/lpadmin -x "$SELECTED" 2>/tmp/ita_err
                    echo "100"
                ) | zenity --progress \
                    --title "$TOOL_NAME" \
                    --window-icon="$SYS_ICON" \
                    --text "🗑️ جاري حذف الطابعة..." \
                    --auto-close --width=$_PW --height=$_PH 2>/dev/null

                read _IW _IH < <(get_win_size medium)
                if ! lpstat -e 2>/dev/null | grep -q "^$SELECTED$"; then
                    zenity --info \
                        --title "نجاح / Success" \
                        --window-icon="$SYS_ICON" \
                        --text "✅ تم الحذف بنجاح!\n\n🖨️  $SELECTED" \
                        --width=$_IW 2>/dev/null
                else
                    ERR_MSG=$(cat /tmp/ita_err 2>/dev/null | head -5)
                    zenity --error \
                        --title "خطأ / Error" \
                        --window-icon="$SYS_ICON" \
                        --text "❌ فشل الحذف.\n\n$ERR_MSG" \
                        --width=$_IW 2>/dev/null
                fi
                rm -f /tmp/ita_err
            fi
            ;;


        4)
            read _W _H < <(get_win_size medium)
            THERMAL_CHOICE=$(zenity --list \
                --title "$TOOL_NAME" \
                --window-icon="$SYS_ICON" \
                --text "إدارة الطابعة الحرارية / Thermal Printer Management:" \
                --radiolist --column "" --column "ID" --column "Action" \
                TRUE  "add"    "🖨️  إضافة طابعة حرارية / Add Thermal Printer" \
                FALSE "remove" "🗑️  حذف طابعة حرارية / Remove Thermal Printer" \
                --width=$_W --height=$_H 2>/dev/null)

            [ -z "$THERMAL_CHOICE" ] && continue

            if [ "$THERMAL_CHOICE" == "add" ]; then


                read _W _H < <(get_win_size medium)
                zenity --warning \
                    --title "⚠️ تنبيه مهم" \
                    --window-icon="$SYS_ICON" \
                    --text "⚠️ برجاء التأكد جيداً من نوع الطابعة قبل الاختيار\n\n🔍 انظر إلى الطابعة بشكل مباشر وتأكد من اسمها:\n    • هل هي SPRT (مكتوب عليها SPRT)؟\n    • أم هي X-Printer XP-80 (مكتوب عليها XP-80)؟\n\n⚡ الاختيار الخاطئ قد يسبب مشكلة في التعريف" \
                    --width=$_W 2>/dev/null



                XP_IMG="/tmp/ita_xprinter.jpg"
                SPRIT_IMG="/tmp/ita_sprit.jpg"
                curl -sfL --connect-timeout 8 \
                    "https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/Icons/Xprinter-xp80.jpg" \
                    -o "$XP_IMG" 2>/dev/null
                curl -sfL --connect-timeout 8 \
                    "https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/Icons/SPRIT.jpg" \
                    -o "$SPRIT_IMG" 2>/dev/null


                THERMAL_BRAND=""
                RESULT_FILE="/tmp/ita_thermal_choice.txt"
                rm -f "$RESULT_FILE"

                DISPLAY_OK=0
                [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && DISPLAY_OK=1

                if [ "$DISPLAY_OK" -eq 1 ] && python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk" 2>/dev/null; then
                    sudo -u "$REAL_USER" python3 - "$XP_IMG" "$SPRIT_IMG" "$RESULT_FILE" "$SYS_ICON" << 'PYEOF'
import sys, os, gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, GdkPixbuf

xp_img_path   = sys.argv[1]
sprit_img_path = sys.argv[2]
result_file    = sys.argv[3]
icon_arg       = sys.argv[4] if len(sys.argv) > 4 else ""

win = Gtk.Window()
win.set_title("اختر نوع الطابعة الحرارية")
if icon_arg:
    try:
        if os.path.isfile(icon_arg):
            win.set_icon_from_file(icon_arg)
        else:
            win.set_icon_name(icon_arg)
    except Exception:
        pass
win.set_border_width(20)
win.set_resizable(False)
win.connect("destroy", Gtk.main_quit)


css = b"""
window { background-color: #1e1e2e; }
label.title { color: #cba6f7; font-size: 16px; font-weight: bold; margin-bottom: 10px; }
button { background: #313244; border: 2px solid #45475a; border-radius: 12px; padding: 12px; }
button:hover { background: #3d3f55; border-color: #cba6f7; }
label.name { color: #cba6f7; font-size: 14px; font-weight: bold; margin-top: 8px; }
label.sub  { color: #a6adc8; font-size: 11px; }
label.warning { color: #f38ba8; font-size: 11px; font-weight: bold; margin-top: 14px; padding: 8px; }
"""
provider = Gtk.CssProvider()
provider.load_from_data(css)
Gtk.StyleContext.add_provider_for_screen(
    win.get_screen(), provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
win.add(main_box)


title = Gtk.Label(label="اختر نوع الطابعة الحرارية")
title.get_style_context().add_class("title")
main_box.pack_start(title, False, False, 0)

cards_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=24)
cards_box.set_halign(Gtk.Align.CENTER)
main_box.pack_start(cards_box, False, False, 0)

def make_card(img_path, name, subtitle, choice_val):
    btn = Gtk.Button()
    btn.get_style_context().add_class("flat")
    inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    inner.set_halign(Gtk.Align.CENTER)

    try:
        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(img_path, 160, 130, True)
        img_widget = Gtk.Image.new_from_pixbuf(pixbuf)
    except Exception:
        img_widget = Gtk.Image.new_from_icon_name("printer", Gtk.IconSize.DIALOG)
    inner.pack_start(img_widget, False, False, 0)
    lbl_name = Gtk.Label(label=name)
    lbl_name.get_style_context().add_class("name")
    inner.pack_start(lbl_name, False, False, 0)
    lbl_sub = Gtk.Label(label=subtitle)
    lbl_sub.get_style_context().add_class("sub")
    inner.pack_start(lbl_sub, False, False, 0)
    btn.add(inner)
    def on_click(b, val=choice_val):
        with open(result_file, 'w') as f:
            f.write(val)
        Gtk.main_quit()
    btn.connect("clicked", on_click)
    return btn

cards_box.pack_start(make_card(xp_img_path,   "X-Printer", "XP-80 Series",    "xprinter"), False, False, 0)
cards_box.pack_start(make_card(sprit_img_path, "SPRT",      "80mm Thermal",    "sprt"),     False, False, 0)

# ── نوت تحذيرية تحت الكروت ──
note_label = Gtk.Label(label="⚠️ برجاء التأكد جيداً من اختيار نوع الطابعة\nلأنه عند اختيار نوع مختلف لن تعمل الطابعة")
note_label.get_style_context().add_class("warning")
note_label.set_justify(Gtk.Justification.CENTER)
main_box.pack_start(note_label, False, False, 0)

win.show_all()
Gtk.main()
PYEOF
                    [ -f "$RESULT_FILE" ] && THERMAL_BRAND=$(cat "$RESULT_FILE")
                fi

                # Fallback: zenity عادي لو GTK مش متاح أو المستخدم أغلق النافذة
                if [ -z "$THERMAL_BRAND" ]; then
                    read _W _H < <(get_win_size medium)
                    THERMAL_BRAND=$(zenity --list \
                        --title "$TOOL_NAME" \
                        --window-icon="$SYS_ICON" \
                        --text "اختر نوع الطابعة الحرارية:\n\n⚠️ برجاء التأكد جيداً من اختيار نوع الطابعة\nلأنه عند اختيار نوع مختلف لن تعمل الطابعة" \
                        --radiolist --column "" --column "ID" --column "النوع / Type" \
                        TRUE  "xprinter" "🖨️  X-Printer  (XP-80 Series)" \
                        FALSE "sprt"     "🖨️  SPRT  (80mm Thermal)" \
                        --width=$_W --height=$_H 2>/dev/null)
                fi

                rm -f "$XP_IMG" "$SPRIT_IMG" "$RESULT_FILE"
                [ -z "$THERMAL_BRAND" ] && continue



                USB_DEV=$(sudo -u admin lpinfo -v 2>/dev/null | grep -iE 'usb:/' | awk '{print $2}' | head -1)
                [ -z "$USB_DEV" ] && USB_DEV=$(lpinfo -v 2>/dev/null | grep -iE 'usb:/' | awk '{print $2}' | head -1)

                if [ -z "$USB_DEV" ]; then
                    read _W _H < <(get_win_size medium)
                zenity --warning \
                        --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "⚠️ لم يتم اكتشاف طابعة USB.\n\nتأكد من توصيل الطابعة وتشغيلها." \
                    --width=$_W 2>/dev/null
                    continue
                fi

                THERMAL_LOG="/tmp/ita_thermal.log"
                PROG_FILE="/tmp/ita_thermal_prog.txt"
                rm -f "$THERMAL_LOG" "$PROG_FILE"

                if [ "$THERMAL_BRAND" == "xprinter" ]; then

                    PRINTER_NAME="xp80"
                    XP_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/Drivers/install-xp80"
                    XP_FILE="/tmp/XP-80"

                    (
                        echo "$(date): بدء تحميل XP-80" > "$THERMAL_LOG"
                        echo "10" > "$PROG_FILE"; echo "# 📥 جاري تحميل X-Printer XP-80 driver..." >> "$PROG_FILE"

                        curl -fL --connect-timeout 20 --max-time 120 --retry 2 \
                            -o "$XP_FILE" "$XP_URL" 2>>"$THERMAL_LOG"

                        if [ ! -s "$XP_FILE" ]; then
                            echo "$(date): فشل التحميل" >> "$THERMAL_LOG"
                            echo "FAIL" > "$PROG_FILE"; exit 1
                        fi

                        echo "$(date): اكتمل التحميل — $(du -sh "$XP_FILE" | cut -f1)" >> "$THERMAL_LOG"
                        echo "40" > "$PROG_FILE"; echo "# ⚙️ جاري التثبيت..." >> "$PROG_FILE"

                        chmod 777 "$XP_FILE"
                        cd /tmp && ./XP-80 >>"$THERMAL_LOG" 2>&1

                        echo "72" > "$PROG_FILE"; echo "# 🔄 إعادة تشغيل CUPS..." >> "$PROG_FILE"
                        systemctl restart cups >>"$THERMAL_LOG" 2>&1
                        sleep 2

                        rm -f "$XP_FILE"
                        echo "100" > "$PROG_FILE"; echo "# ✅ اكتمل" >> "$PROG_FILE"
                        echo "DONE" >> "$PROG_FILE"
                    ) &
                    BG_PID=$!

                    read _PW _PH < <(get_win_size progress)
                    (
                        LAST_VAL=5
                        while kill -0 "$BG_PID" 2>/dev/null; do
                            [ -f "$PROG_FILE" ] && {
                                NV=$(grep '^[0-9]' "$PROG_FILE" | tail -1)
                                NM=$(grep '^#' "$PROG_FILE" | tail -1)
                                [ -n "$NV" ] && [ "$NV" != "$LAST_VAL" ] && echo "$NV" && LAST_VAL="$NV"
                                [ -n "$NM" ] && echo "$NM"
                                grep -q "^FAIL" "$PROG_FILE" 2>/dev/null && break
                            }
                            sleep 1
                        done
                        echo "100"; echo "# ✅ اكتمل / Done"
                    ) | zenity --progress \
                        --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "⚙️ جاري تثبيت تعريف X-Printer XP-80..." \
                        --width=$_PW --height=$_PH --no-cancel 2>/dev/null

                    wait "$BG_PID"
                    rm -f "$PROG_FILE"


                    XP_PPD=$(lpinfo -m 2>/dev/null | grep -i "XP-80\|XP80\|xprinter" | head -1 | awk '{print $1}')

                    if [ -z "$XP_PPD" ]; then
                        read _EW _EH < <(get_win_size medium)
                        zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                            --text "❌ لم يتم العثور على تعريف XP-80 بعد التثبيت.\n\nLog: $THERMAL_LOG" \
                            --width=$_EW 2>/dev/null
                        continue
                    fi

                    read _PW _PH < <(get_win_size progress)
                    (
                        echo "20"
                        lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$" \
                            && sudo -u admin /usr/sbin/lpadmin -x "$PRINTER_NAME" 2>/dev/null
                        echo "45"
                        sudo -u admin /usr/sbin/lpadmin \
                            -p "$PRINTER_NAME" -E \
                            -v "$USB_DEV" \
                            -m "$XP_PPD" \
                            -D "X-Printer XP-80" \
                            2>/tmp/ita_err
                        echo "65"
                        sudo -u admin /usr/sbin/cupsenable "$PRINTER_NAME" 2>/dev/null
                        sudo -u admin /usr/sbin/cupsaccept "$PRINTER_NAME" 2>/dev/null
                        echo "82"
                        set_thermal_defaults "$PRINTER_NAME"
                        echo "100"
                    ) | zenity --progress \
                        --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "🖨️ جاري إضافة X-Printer XP-80..." \
                        --auto-close --width=$_PW --height=$_PH 2>/dev/null

                    read _IW _IH < <(get_win_size medium)
                    if lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$"; then
                        zenity --info --title "نجاح / Success" --window-icon="$SYS_ICON" \
                            --text "✅ تمت إضافة X-Printer XP-80 بنجاح!\n\n🖨️ الاسم: $PRINTER_NAME\n🔌 USB: $USB_DEV\n📄 Paper: 80mm" \
                            --width=$_IW 2>/dev/null
                    else
                        ERR_MSG=$(cat /tmp/ita_err 2>/dev/null | head -5)
                        zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                            --text "❌ فشلت إضافة الطابعة.\n\n$ERR_MSG" \
                            --width=$_IW 2>/dev/null
                    fi
                    rm -f /tmp/ita_err

                elif [ "$THERMAL_BRAND" == "sprt" ]; then

                    PRINTER_NAME="SPRT"
                    SPRIT_DIR="/tmp/sprit_driver_extract"
                    SPRIT_BASE_URL="https://raw.githubusercontent.com/mahmoudkassem30/Printers-Tools/dbd1722a4ffac9f42856d9d3f70faa2874d1fd93/sources/Drivers/install-SPRIT"

                    (
                        echo "$(date): بدء تحميل SPRT" > "$THERMAL_LOG"
                        echo "10" > "$PROG_FILE"; echo "# 📥 جاري تحميل ملفات SPRT driver..." >> "$PROG_FILE"

                        rm -rf "$SPRIT_DIR"; mkdir -p "$SPRIT_DIR"

                        DOWNLOAD_OK=1
                        for FNAME in 80mmSeries.ppd install.sh rastertoprinter rastertoprintercm rastertoprinterlm; do
                            curl -fL --connect-timeout 20 --max-time 60 --retry 2 \
                                -o "$SPRIT_DIR/$FNAME" \
                                "$SPRIT_BASE_URL/$FNAME" 2>>"$THERMAL_LOG"
                            if [ $? -ne 0 ] || [ ! -s "$SPRIT_DIR/$FNAME" ]; then
                                echo "$(date): فشل تحميل $FNAME" >> "$THERMAL_LOG"
                                DOWNLOAD_OK=0
                            else
                                echo "$(date): تم تحميل $FNAME" >> "$THERMAL_LOG"
                            fi
                        done

                        if [ "$DOWNLOAD_OK" -eq 0 ]; then
                            echo "FAIL" > "$PROG_FILE"; exit 1
                        fi

                        echo "35" > "$PROG_FILE"; echo "# ⚙️ جاري تشغيل install.sh..." >> "$PROG_FILE"

                        chmod +x "$SPRIT_DIR/install.sh" \
                                  "$SPRIT_DIR/rastertoprinter" \
                                  "$SPRIT_DIR/rastertoprintercm" \
                                  "$SPRIT_DIR/rastertoprinterlm" 2>>"$THERMAL_LOG"

                        INSTALLER="$SPRIT_DIR/install.sh"
                        (
                            cd "$SPRIT_DIR" || exit 1
                            ./install.sh
                        ) >>"$THERMAL_LOG" 2>&1
                        echo "$(date): install.sh اكتمل" >> "$THERMAL_LOG"

                        # fallback قوي: تأكيد نسخ فلاتر CUPS + ملفات PPD
                        SERVERROOT=$(awk '/^[[:space:]]*ServerRoot[[:space:]]+/ {print $2; exit}' /etc/cups/cupsd.conf)
                        SERVERBIN=$(awk '/^[[:space:]]*ServerBin[[:space:]]+/ {print $2; exit}' /etc/cups/cupsd.conf)
                        DATADIR=$(awk '/^[[:space:]]*DataDir[[:space:]]+/ {print $2; exit}' /etc/cups/cupsd.conf)

                        if [ -z "$SERVERBIN" ]; then
                            FILTERDIR="/usr/lib/cups/filter"
                        elif [ "${SERVERBIN:0:1}" = "/" ]; then
                            FILTERDIR="$SERVERBIN/filter"
                        else
                            FILTERDIR="$SERVERROOT/$SERVERBIN/filter"
                        fi

                        if [ -z "$DATADIR" ]; then
                            PPDDIR="/usr/share/cups/model/printer"
                        elif [ "${DATADIR:0:1}" = "/" ]; then
                            PPDDIR="$DATADIR/model/printer"
                        else
                            PPDDIR="$SERVERROOT/$DATADIR/model/printer"
                        fi

                        mkdir -p "$FILTERDIR" "$PPDDIR" /usr/lib/cups/filter
                        for FNAME in rastertoprinter rastertoprinterlm rastertoprintercm; do
                            if [ -f "$SPRIT_DIR/$FNAME" ]; then
                                cp -f "$SPRIT_DIR/$FNAME" "$FILTERDIR/$FNAME" 2>>"$THERMAL_LOG"
                                chmod +x "$FILTERDIR/$FNAME" 2>>"$THERMAL_LOG"
                                cp -f "$SPRIT_DIR/$FNAME" "/usr/lib/cups/filter/$FNAME" 2>>"$THERMAL_LOG"
                                chmod +x "/usr/lib/cups/filter/$FNAME" 2>>"$THERMAL_LOG"
                            fi
                        done

                        mkdir -p /usr/share/cups/model/SPRIT
                        cp -f "$SPRIT_DIR/80mmSeries.ppd" /usr/share/cups/model/SPRIT/ 2>>"$THERMAL_LOG"

                        echo "78" > "$PROG_FILE"; echo "# 🔄 إعادة تشغيل CUPS..." >> "$PROG_FILE"
                        systemctl restart cups >>"$THERMAL_LOG" 2>&1
                        sleep 2

                        echo "100" > "$PROG_FILE"; echo "# ✅ اكتمل التثبيت" >> "$PROG_FILE"
                        echo "DONE" >> "$PROG_FILE"
                    ) &
                    BG_PID=$!

                    read _PW _PH < <(get_win_size progress)
                    (
                        LAST_VAL=5
                        while kill -0 "$BG_PID" 2>/dev/null; do
                            [ -f "$PROG_FILE" ] && {
                                NV=$(grep '^[0-9]' "$PROG_FILE" | tail -1)
                                NM=$(grep '^#' "$PROG_FILE" | tail -1)
                                [ -n "$NV" ] && [ "$NV" != "$LAST_VAL" ] && echo "$NV" && LAST_VAL="$NV"
                                [ -n "$NM" ] && echo "$NM"
                                grep -q "^FAIL" "$PROG_FILE" 2>/dev/null && break
                            }
                            sleep 1
                        done
                        echo "100"; echo "# ✅ اكتمل / Done"
                    ) | zenity --progress \
                        --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "⚙️ جاري تثبيت تعريف SPRT..." \
                        --width=$_PW --height=$_PH --no-cancel 2>/dev/null

                    wait "$BG_PID"
                    rm -f "$PROG_FILE"


                    SPRIT_PPD_DEST="/usr/share/cups/model/SPRIT/80mmSeries.ppd"

                    if [ ! -f "$SPRIT_PPD_DEST" ]; then
                        read _EW _EH < <(get_win_size medium)
                        zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                            --text "❌ لم يتم العثور على 80mmSeries.ppd.\n\nLog: $THERMAL_LOG" \
                        --width=$_EW 2>/dev/null
                        rm -rf "$SPRIT_DIR"
                        continue
                    fi


                    if [ ! -x "/usr/lib/cups/filter/rastertoprinter" ] && [ ! -x "$FILTERDIR/rastertoprinter" ]; then
                        read _EW _EH < <(get_win_size medium)
                        zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                            --text "❌ فلتر الطباعة rastertoprinter غير موجود.\n\nLog: $THERMAL_LOG" \
                            --width=$_EW 2>/dev/null
                        rm -rf "$SPRIT_DIR"
                        continue
                    fi


                    if grep -qi "FullCut\|Full Cut\|CutType\|AutoCut" "$SPRIT_PPD_DEST" 2>/dev/null; then
                        sed -i 's/\*DefaultCutType:.*/\*DefaultCutType: FullCut/gI' "$SPRIT_PPD_DEST" 2>/dev/null
                        sed -i 's/\*DefaultAutoCut:.*/\*DefaultAutoCut: FullCut/gI' "$SPRIT_PPD_DEST" 2>/dev/null
                    fi

                    systemctl restart cups 2>/dev/null; sleep 1

                    read _PW _PH < <(get_win_size progress)
                    (
                        echo "20"
                        lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$" \
                            && sudo -u admin /usr/sbin/lpadmin -x "$PRINTER_NAME" 2>/dev/null
                        echo "45"
                        sudo -u admin /usr/sbin/lpadmin \
                            -p "$PRINTER_NAME" -E \
                            -v "$USB_DEV" \
                            -P "$SPRIT_PPD_DEST" \
                            -D "SPRT 80mm Thermal" \
                            2>/tmp/ita_err
                        echo "65"
                        sudo -u admin /usr/sbin/cupsenable "$PRINTER_NAME" 2>/dev/null
                        sudo -u admin /usr/sbin/cupsaccept "$PRINTER_NAME" 2>/dev/null
                        echo "80"
                        set_thermal_defaults "$PRINTER_NAME"
                        echo "100"
                    ) | zenity --progress \
                        --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "🖨️ جاري إضافة SPRT..." \
                        --auto-close --width=$_PW --height=$_PH 2>/dev/null

                    rm -rf "$SPRIT_DIR"

                    read _IW _IH < <(get_win_size medium)
                    if lpstat -e 2>/dev/null | grep -q "^$PRINTER_NAME$"; then
                        zenity --info --title "نجاح / Success" --window-icon="$SYS_ICON" \
                            --text "✅ تمت إضافة SPRT بنجاح!\n\n🖨️ الاسم: $PRINTER_NAME\n🔌 USB: $USB_DEV\n📄 PPD: 80mmSeries\n✂️ Cut: Full Cut\n📄 Media: 80mm x 297mm" \
                            --width=$_IW 2>/dev/null
                    else
                        ERR_MSG=$(cat /tmp/ita_err 2>/dev/null | head -5)
                        zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                            --text "❌ فشلت إضافة الطابعة.\n\n$ERR_MSG" \
                            --width=$_IW 2>/dev/null
                    fi
                    rm -f /tmp/ita_err
                fi
            elif [ "$THERMAL_CHOICE" == "remove" ]; then
                read _W _H < <(get_win_size medium)

                ALL_PRINTERS=$(lpstat -e 2>/dev/null)
                if [ -z "$ALL_PRINTERS" ]; then
                    zenity --warning --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                        --text "⚠️ لا توجد طابعات مضافة في النظام." \
                        --width=$_W 2>/dev/null
                    continue
                fi

                ZENITY_ARGS=()
                while read -r PNAME; do
                    [ -z "$PNAME" ] && continue
                    URI=$(lpstat -v "$PNAME" 2>/dev/null | awk '{print $NF}')
                    if echo "$URI" | grep -qiE 'usb|direct|parallel'; then
                        PTYPE="🔌 USB / حرارية"
                    elif echo "$URI" | grep -qiE 'ipp|lpd|socket'; then
                        PTYPE="🌐 شبكة"
                    else
                        PTYPE="❓ أخرى"
                    fi
                    ZENITY_ARGS+=("$PNAME" "$PTYPE" "$URI")
                done <<< "$ALL_PRINTERS"

                read _W _H < <(get_win_size wide)
                SELECTED=$(zenity --list \
                    --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                    --text "🗑️ اختر الطابعة للحذف:" \
                    --column "الاسم / Name" --column "النوع / Type" --column "العنوان / URI" \
                    --print-column=1 "${ZENITY_ARGS[@]}" \
                    --width=$_W --height=$_H 2>/dev/null)

                [ -z "$SELECTED" ] && continue

                read _W _H < <(get_win_size medium)
                zenity --question --title "تأكيد / Confirm" --window-icon="$SYS_ICON" \
                    --text "⚠️ هل أنت متأكد من حذف:\n\n🖨️  $SELECTED" \
                    --ok-label="نعم، احذف / Yes, Remove" \
                    --cancel-label="إلغاء / Cancel" --width=$_W 2>/dev/null

                [ $? -ne 0 ] && continue

                read _PW _PH < <(get_win_size progress)
                (
                    echo "20"

                    sudo -u admin /usr/sbin/cancel -a "$SELECTED" 2>/dev/null
                    cancel -a "$SELECTED" 2>/dev/null
                    echo "50"

                    sudo -u admin /usr/sbin/cupsdisable "$SELECTED" 2>/dev/null
                    sleep 1
                    echo "70"

                    sudo -u admin /usr/sbin/lpadmin -x "$SELECTED" 2>/tmp/ita_err
                    echo "100"
                ) | zenity --progress \
                    --title "$TOOL_NAME" --window-icon="$SYS_ICON" \
                    --text "🗑️ جاري حذف الطابعة..." \
                    --auto-close --width=$_PW --height=$_PH 2>/dev/null

                read _IW _IH < <(get_win_size medium)
                if ! lpstat -e 2>/dev/null | grep -q "^$SELECTED$"; then
                    zenity --info --title "نجاح / Success" --window-icon="$SYS_ICON" \
                        --text "✅ تم الحذف بنجاح!\n\n🖨️  $SELECTED" \
                        --width=$_IW 2>/dev/null
                else
                    ERR_MSG=$(cat /tmp/ita_err 2>/dev/null | head -5)
                    zenity --error --title "خطأ / Error" --window-icon="$SYS_ICON" \
                        --text "❌ فشل الحذف.\n\n$ERR_MSG" \
                        --width=$_IW 2>/dev/null
                fi
                rm -f /tmp/ita_err
            fi
            ;;

        5)
            read _PW _PH < <(get_win_size progress)
            (echo "50"; systemctl stop cups; rm -rf /var/spool/cups/*; systemctl start cups; echo "100") | zenity --progress --text "$TXT_WAIT" --auto-close 2>/dev/null
            read _W _H < <(get_win_size medium)
            zenity --info --text "$TXT_SUCCESS" 2>/dev/null
            ;;

    esac
done
