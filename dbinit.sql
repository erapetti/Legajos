CREATE TABLE `orden` (
  `FncEsGrupI` smallint(6) NOT NULL,
  `FncEsDepto` smallint(6) NOT NULL,
  `FncCedula` int(11) NOT NULL,
  `orden` int(10) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`FncEsGrupI`,`FncEsDepto`,`FncCedula`),
  KEY `orden` (`orden`)
) ENGINE=InnoDB AUTO_INCREMENT=48105 DEFAULT CHARSET=utf8;
