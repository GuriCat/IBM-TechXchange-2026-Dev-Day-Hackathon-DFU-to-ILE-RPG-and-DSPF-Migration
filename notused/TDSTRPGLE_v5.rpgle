     H DFTACTGRP(*NO) ACTGRP(*NEW)
     H OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
     H DATEDIT(*YMD)
     FQCUSTCDT  UF A E           K DISK    USROPN INFDS(dbfds)
     F                                     INFSR(#DBEX)
     FTDSTDSPF  CF   E             WORKSTN INDDS(ws)
     FTDSTPRTR  O    E             PRINTER USROPN
     D                SDS
     D pgmNam            *PROC
     Ddbfds            DS
     D  dbfStatus             11     15
     D  dbfOpr               *OPCODE
     Dws               DS
     D  exit_03                        N   OVERLAY(ws:3)
     D  refresh_05                     N   OVERLAY(ws:5)
     D  insert_09                      N   OVERLAY(ws:9)
     D  input_10                       N   OVERLAY(ws:10)
     D  change_11                      N   OVERLAY(ws:11)
     D  advance_14                     N   OVERLAY(ws:14)
     D  cancel_12                      N   OVERLAY(ws:12)
     D  del_23                         N   OVERLAY(ws:23)
     D  fldChange_30                   N   OVERLAY(ws:30)
     D  errorMsg_50                    N   OVERLAY(ws:50)
     D  infoMsg_51                     N   OVERLAY(ws:51)
     D  dspDetail_60                   N   OVERLAY(ws:60)
     D  fieldRI_PR_61                  N   OVERLAY(ws:61)
     DADDCNT           S              5P 0 INZ(0)
     DCHGCNT           S              5P 0 INZ(0)
     DDLTCNT           S              5P 0 INZ(0)
     DwkMode           S              1A   INZ('C')
     DdspMsg           S             50A
     Dwait             S              1A
     DreturnPt         S              6A

        // ============================================================
        // TDSTRPGLE - DFU Replacement for TESTDFU / QIWS/QCUSTCDT
        // Library : GURILIB  Source : QRPGLESRC  Member : TDSTRPGLE
        // ============================================================

        // Open files
        OPEN QCUSTCDT;
        OPEN TDSTPRTR;

        // Position to first record
        SETLL(E) *LOVAL QCUSTCDTR;
        IF NOT %ERROR;
          READ(E) QCUSTCDTR;
          IF NOT %EOF;
            ws.dspDetail_60 = *ON;
          ENDIF;
        ENDIF;

        // Initial state: Change mode, clear message fields
        wkMode           = 'C';
        ws.fieldRI_PR_61 = *OFF;
        ws.errorMsg_50   = *OFF;
        ws.infoMsg_51    = *OFF;
        MSGDTA           = *BLANKS;
        MSGDTB           = *BLANKS;

        DOW (1 = 1);

          EXSR #SETMOD;
          EXFMT MAINR;

          ws.errorMsg_50 = *OFF;
          ws.infoMsg_51  = *OFF;
          MSGDTA         = *BLANKS;
          MSGDTB         = *BLANKS;

          SELECT;

            WHEN ws.exit_03;
              EXSR #ENDSES;
              LEAVE;

            WHEN ws.refresh_05;
              IF ws.dspDetail_60;
                CHAIN(E) CUSNUM QCUSTCDTR;
                EXSR #DBEX;
                IF NOT %FOUND;
                  EXSR #CLRSCR;
                  ws.errorMsg_50 = *ON;
                  MSGDTA = ' Record not found.';
                ENDIF;
              ELSE;
                EXSR #CLRSCR;
              ENDIF;

            WHEN ws.insert_09;
              wkMode          = 'A';
              EXSR #CLRSCR;
              ws.dspDetail_60 = *ON;

            WHEN ws.input_10;
              wkMode          = 'I';
              EXSR #CLRSCR;
              ws.dspDetail_60 = *ON;

            WHEN ws.change_11;
              wkMode = 'C';
              IF ws.dspDetail_60;
                CHAIN(E) CUSNUM QCUSTCDTR;
                EXSR #DBEX;
              ENDIF;

            WHEN ws.advance_14;
              IF ws.dspDetail_60 AND ws.fldChange_30;
                EXSR #COMMIT;
              ENDIF;
              IF NOT ws.errorMsg_50;
                EXSR #RDNXT;
              ENDIF;

            WHEN ws.del_23;
              IF ws.dspDetail_60;
                EXSR #DELREC;
              ENDIF;

            OTHER;
              IF ws.dspDetail_60 AND ws.fldChange_30;
                EXSR #COMMIT;
              ELSE;
                EXSR #CHAIN;
              ENDIF;

          ENDSL;

        ENDDO;

        *INLR = *ON;
        RETURN;

       // ============================================================
       // #SETMOD  Map wkMode to 7-char CURMODE display field
       // ============================================================
       BEGSR #SETMOD;
       SELECT;
         WHEN wkMode = 'C';
           CURMODE = 'Change ';
         WHEN wkMode = 'I';
           CURMODE = 'Input  ';
         OTHER;
           CURMODE = 'Insert ';
       ENDSL;
       ENDSR;

       // ============================================================
       // #CLRSCR  Clear record buffer and hide detail section
       // ============================================================
       BEGSR #CLRSCR;
       CLEAR QCUSTCDTR;
       ws.dspDetail_60  = *OFF;
       ws.fieldRI_PR_61 = *OFF;
       ENDSR;

       // ============================================================
       // #CHAIN  Position by RECNBR key entered on screen
       // ============================================================
       BEGSR #CHAIN;
       CHAIN(E) RECNBR QCUSTCDTR;
       EXSR #DBEX;
       IF NOT %FOUND;
         ws.errorMsg_50   = *ON;
         MSGDTA           = ' Record not found.';
         ws.dspDetail_60  = *OFF;
       ELSE;
         ws.dspDetail_60  = *ON;
         ws.fieldRI_PR_61 = *OFF;
       ENDIF;
       ENDSR;

       // ============================================================
       // #COMMIT  Update (Change mode) or Write (Input/Insert mode)
       // ============================================================
       BEGSR #COMMIT;
       IF wkMode = 'C';
         UPDATE(E) QCUSTCDTR;
         IF %ERROR;
           ws.errorMsg_50 = *ON;
           MSGDTA = ' Update error (' + dbfOpr + ',' + dbfStatus + ')';
         ELSE;
           CHGCNT        += 1;
           ws.infoMsg_51  = *ON;
           MSGDTB         = ' Record updated.';
         ENDIF;
       ELSE;
         IF CUSNUM = 0;
           ws.errorMsg_50 = *ON;
           MSGDTA         = ' CUSNUM is required.';
         ELSE;
           WRITE(E) QCUSTCDTR;
           IF %ERROR;
             ws.errorMsg_50 = *ON;
             MSGDTA = ' Write error (' + dbfOpr + ',' + dbfStatus + ')';
           ELSE;
             ADDCNT        += 1;
             ws.infoMsg_51  = *ON;
             MSGDTB         = ' Record added.';
             CHAIN(E) CUSNUM QCUSTCDTR;
             EXSR #DBEX;
             wkMode          = 'C';
             ws.dspDetail_60 = *ON;
           ENDIF;
         ENDIF;
       ENDIF;
       ENDSR;

       // ============================================================
       // #RDNXT  Read next record; wrap to first on EOF
       // ============================================================
       BEGSR #RDNXT;
       READ(E) QCUSTCDTR;
       EXSR #DBEX;
       IF %EOF;
         SETLL(E) *LOVAL QCUSTCDTR;
         READ(E) QCUSTCDTR;
         EXSR #DBEX;
         ws.infoMsg_51 = *ON;
         MSGDTB = ' End of file -- wrapped to first.';
       ENDIF;
       ws.dspDetail_60 = *ON;
       ENDSR;

       // ============================================================
       // #DELREC  Show protected screen, confirm with F23, then delete
       // ============================================================
       BEGSR #DELREC;
       ws.fieldRI_PR_61 = *ON;
       ws.infoMsg_51    = *ON;
       MSGDTB = ' Press F23 again to delete. F3/ENTER to cancel.';
       EXFMT MAINR;
       ws.infoMsg_51  = *OFF;
       ws.errorMsg_50 = *OFF;
       MSGDTA         = *BLANKS;
       MSGDTB         = *BLANKS;
       IF ws.del_23;
         DELETE(E) QCUSTCDTR;
         IF %ERROR;
           ws.errorMsg_50  = *ON;
           MSGDTA = ' Delete error (' + dbfOpr + ',' + dbfStatus + ')';
           ws.dspDetail_60 = *ON;
         ELSE;
           DLTCNT          += 1;
           EXSR #RDNXT;
           ws.infoMsg_51   = *ON;
           MSGDTB          = ' Record deleted.';
         ENDIF;
       ELSE;
         ws.infoMsg_51 = *ON;
         MSGDTB        = ' Delete cancelled.';
       ENDIF;
       ws.fieldRI_PR_61 = *OFF;
       ENDSR;

       // ============================================================
       // #ENDSES  Display end-of-session screen; call #PRTRPT if Y
       // ============================================================
       BEGSR #ENDSES;
       ENDYES = 'Y';
       EXFMT ENDR;
       IF ws.exit_03 OR ENDYES = 'Y' OR ENDYES = 'y';
         EXSR #PRTRPT;
       ENDIF;
       ENDSR;

       // ============================================================
       // #PRTRPT  Write DFU-compatible audit report to TDSTPRTR
       // ============================================================
       BEGSR #PRTRPT;
       HDRDAT = %CHAR(%DATE() : *YMD/);
       HDRTIM = %CHAR(%TIME() : *HMS:);
       HDRPAG = 1;
       WRITE HDR;
       WRITE PGM;
       WRITE MBR;
       WRITE JOB;
       CNTVAL = ADDCNT;
       CNTTXT = 'records added';
       WRITE CNTLIN;
       CNTVAL = CHGCNT;
       CNTTXT = 'records changed';
       WRITE CNTLIN;
       CNTVAL = DLTCNT;
       CNTTXT = 'records deleted';
       WRITE CNTLIN;
       WRITE FOOTER;
       CLOSE TDSTPRTR;
       ENDSR;

       // ============================================================
       // #DBEX  DB I/O exception handler (INFSR target)
       // ============================================================
       BEGSR #DBEX;
       IF %ERROR;
         dspMsg = 'DB error: ' + dbfOpr + ' ' + dbfStatus;
         DSPLY dspMsg wait;
         returnPt = '*CANCL';
       ELSE;
         returnPt = *BLANKS;
       ENDIF;
     C                   ENDSR     returnPt
