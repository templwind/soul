apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{.serviceName}}
  namespace: {{.serviceName}}
  labels:
    app: {{.serviceName}}
spec:
  replicas: 3
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: {{.serviceName}}
  template:
    metadata:
      labels:
        app: {{.serviceName}}
    spec:
      containers:
        - name: {{.serviceName}}
          image: registry.digitalocean.com/YOUR_REPO/{{.serviceName}}-app:main-latest
          ports:
            - containerPort: 8888
          readinessProbe:
            tcpSocket:
              port: 8888
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            tcpSocket:
              port: 8888
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1024Mi
          volumeMounts:
            - name: timezone
              mountPath: /etc/localtime
      volumes:
        - name: timezone
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai

---
apiVersion: v1
kind: Service
metadata:
  name: {{.serviceName}}-svc
  namespace: {{.serviceName}}
spec:
  ports:
    - port: 8888
      targetPort: 8888
  selector:
    app: {{.serviceName}}

---
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: {{.serviceName}}-hpa-c
  namespace: {{.serviceName}}
  labels:
    app: {{.serviceName}}-hpa-c
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{.serviceName}}
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80

---
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: {{.serviceName}}-hpa-m
  namespace: {{.serviceName}}
  labels:
    app: {{.serviceName}}-hpa-m
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{.serviceName}}
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
