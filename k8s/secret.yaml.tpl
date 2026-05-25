apiVersion: v1
kind: Secret
metadata:
  name: helpdesk-secret
  namespace: default
  labels:
    app: helpdesk-app
    Project: fs_support_app
type: Opaque
data:
  DB_HOST: ${db_host_base64}
  DB_USER: ${db_user_base64}
  DB_PASSWORD: ${db_password_base64}
  DB_NAME: ${db_name_base64}
