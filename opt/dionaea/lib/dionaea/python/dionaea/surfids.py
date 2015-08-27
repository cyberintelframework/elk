from dionaea.core import ihandler, incident, g_dionaea
from dionaea.smb import smb

import os
import logging
import random

logger = logging.getLogger('surfids')
logger.setLevel(logging.DEBUG)

AS_POSSIBLE_MALICIOUS_CONNECTION   = 0x00000
AS_DEFINITLY_MALICIOUS_CONNECTION  = 0x00001

AS_DOWNLOAD_OFFER                  = 0x00010
AS_DOWNLOAD_SUCCESS                = 0x00020


DT_PROTOCOL_NAME                   = 80
DT_EMULATION_PROFILE               = 81
DT_SHELLCODE_ACTION                = 82
DT_DCERPC_REQUEST                  = 83
DT_VULN_NAME                       = 84

class surfidshandler(ihandler):
	def __init__(self, path):
		logger.debug("%s ready!" % (self.__class__.__name__))
		ihandler.__init__(self, path)

		# mapping socket -> attackid
		self.attacks = {}

		self.dbh = None

	def handle_incident(self, icd):
		origin = icd.origin
		origin = origin.replace(".","_")
		try:
			method = getattr(self, "_handle_incident_" + origin)
		except:
			return

		while True:
			try:
				method(icd)
				return
			except ConnectionError as e:
				logger.warn("ConnectionError %s" % e)
				time.sleep(1)

	def _handle_incident_dionaea_connection_tcp_accept(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] tcp accept" % 
			(con.remote.host, con.remote.port, con.local.host, con.local.port))

	def _handle_incident_dionaea_connection_tcp_connect(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] tcp connect (hostname: %s)" %
			(con.remote.host, con.remote.port, con.local.host, con.local.port, con.remote.hostname))

	def _handle_incident_dionaea_connection_tcp_reject(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] tcp reject" % 
			(con.remote.host, con.remote.port, con.local.host, con.local.port))

	def _handle_incident_dionaea_connection_free(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] tcp disconnect" % (con.remote.host, con.remote.port, con.local.host, con.local.port) )

	def _handle_incident_dionaea_module_emu_profile(self, icd):
		con = icd.con
		logger.info("[%s:%i to %s:%i] emuprofile %s" % (con.remote.host, con.remote.port, con.local.host, con.local.port, str(icd.profile)))

	def _handle_incident_dionaea_download_offer(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] download offer %s" % (con.remote.host, con.remote.port, con.local.host, con.local.port, icd.url))

	def _handle_incident_dionaea_download_complete_hash(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] download complete url %s with hash %s" % (con.remote.host, con.remote.port, con.local.host, con.local.port, icd.url, icd.md5hash))

	def _handle_incident_dionaea_service_shell_listen(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] listen shell %s" % (con.remote.host, con.remote.port, con.local.host, con.local.port, "bindshell://"+str(icd.port)))

	def _handle_incident_dionaea_service_shell_connect(self, icd):
		con=icd.con
		logger.info("[%s:%i to %s:%i] connect shell %s" % (con.remote.host, con.remote.port, con.local.host, con.local.port, "connectbackshell://"+str(icd.host)+":"+str(icd.port)))
		
	def _handle_incident_dionaea_modules_python_smb_dcerpc_request(self, icd):
		con=icd.con
		myuuid = icd.uuid.replace('-', '')
		try:
				vuln = smb.registered_services[myuuid].vulns[icd.opnum]
		except:
				vuln = "SMBDialogue"
   
		logger.info("dcerpc request for attackid %i" % attackid)
		logger.info("[%s:%i to %s:%i] dcerpc request %s (vulernability: %s)" % (con.remote.host, con.remote.port, con.local.host, con.local.port, icd.uuid + ":" + str(icd.opnum), vuln))
