# CFS G32 — CFG6 SGF1/RH1 R3

Il menu **40** propone prima **R3**, poi **RDG2** come fallback.
R3 richiede il [ramo Kalico k2-pro-openhost](https://github.com/MzTechnology97/kalico-k2pro/tree/k2-pro-openhost)
con l'extra box_spool_profiles e l'integrazione Box corrispondente.

- File: [cfs0_050_G32-cfs0_000_153-K2OH-CFG6-SGF1-RH1-R3-CANDIDATE.bin](cfs0_050_G32-cfs0_000_153-K2OH-CFG6-SGF1-RH1-R3-CANDIDATE.bin)
- Dimensione: 185900 byte.
- SHA-256: `a6dec25c74e7d259eec0387193548a0c3cc78ec9fc4ddc35824f0fe0965385b8`.
- Destinazione: esclusivamente CFS G32 / applicazione cfs0_000_153.

Il suffisso CANDIDATE conserva il nome del BIN effettivamente provato.
Sul riferimento sono verificati lettura Bambu PETG HF negli slot 2/4 con un
ciclo RH1 ciascuno, UID coerenti (flags 0x13), catalogo RAM, lunghezze per UID,
consumo e cambio automatico al runout. Non estende la prova a tutte le schede,
tutti i tag o tutti i percorsi. Il [manifest dettagliato](SGF1-RH1-R3-firmware-manifest.json)
riporta l'ambito.

Installare il [file conf](https://github.com/MzTechnology97/kalico-k2pro/blob/k2-pro-openhost/config/k2/macros/box_spool_profiles.cfg)
e seguire la [guida di calibrazione](https://github.com/MzTechnology97/kalico-k2pro/blob/k2-pro-openhost/docs/CFS_SPOOL_CALIBRATION.md).
Profilo Bambu: `bambu = 1, 284.7, 508.3`, circonferenze in mm.
Il nucleo effettivo deriva dal primo esaurimento e attende una seconda prova:
non è il diametro fisico del cartone. Cambiare il profilo non richiede un
nuovo BIN.

Prima del flash terminare stampa, carico e scarico. Il controllo host richiede
stampante/CFS inattivi e rifiuta lo stato non disponibile. Seguire il menu
supervisionato e digitare esattamente `FLASH EXPERIMENTAL CFS`.
Usare bootstrap T113 0.1.2 o successivo, che conserva il nome applicazione OEM.
Riavviare Kalico soltanto a stampante inattiva. Conservare il recupero OEM.

Il fallback RDG2 ha SHA-256
`7d611c5845d3c248cf55f57972fdc7fab1761d0e281bcbf70030ac97e458023f`.
Sul riferimento erano verificati RFID e decremento 39→34; non include la
geometria SGF1/RH1.
