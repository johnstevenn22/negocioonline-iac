# Contexto del Proyecto: Sistema de Pedidos Online - Arquitectura AWS con Terraform

## 1. Identidad y Objetivo del Proyecto

* [cite_start]**Proyecto**: Plataforma de Pedidos Online para una Cadena de Restaurantes [3 sedes en Trujillo](cite: 2, 10).
* [cite_start]**Problema Principal**: Saturación del sistema en alta demanda y falta de sincronización de stock en tiempo real[cite: 8, 9].
* **Objetivo Técnico**: Evolucionar una arquitectura de infraestructura estática a un modelo de Microservicios Contenerizados con despliegue automatizado (CI/CD).

## 2. Requisitos No Funcionales Críticos (KPIs)

* **Rendimiento**: Tiempo de respuesta < 1.5s; [cite_start]Cache Hit Ratio ≥ 85% [Redis](cite: 15, 18).
* **Escalabilidad**: Soportar 50-100 usuarios concurrentes; [cite_start]Auto Scaling activo cuando CPU > 60%[cite: 22, 23, 25].
* [cite_start]**Confiabilidad**: RDS Multi-AZ y notificaciones SNS ante fallos en < 30s[cite: 30, 31, 32].
* **Seguridad**: Protección WAF (tasa de bloqueo ≥ 95%), principio de mínimo privilegio (IAM) y cero credenciales expuestas.

## 3. Estado Actual de la Infraestructura (Terraform)

Actualmente el proyecto cuenta con:

* **Red**: VPC con subredes públicas y privadas en la región `us-east-2` (Ohio).
* **Seguridad**: WAF asociado al Application Load Balancer (ALB).
* **Cómputo (A EVOLUCIONAR)**: Actualmente usa EC2 (instancias fijas) y un Auto Scaling Group (ASG).
* **Datos**: PostgreSQL en RDS (Multi-AZ) y ElastiCache (Redis).
* **Monitoreo**: Dashboard en CloudWatch, alarmas de CPU, SQS para errores y Lambda para procesamiento de fallos.
* [cite_start]**Respaldo**: AWS Backup con plan de retención diario (incremental) y mensual [full](cite: 57).

## 4. Guía de Estilo y Restricciones de Código

* **Sin Comentarios**: Eliminar comentarios explicativos dentro del código Terraform; el código debe ser auto-explicativo.
* **Seguridad de Credenciales**: Está terminantemente prohibido hardcodear contraseñas o llaves. Se debe usar `variables.tf`, archivos `.tfvars` (protegidos por .gitignore) o integrar AWS Secrets Manager.
* **Explicabilidad**: Cada bloque de código debe ser justificable técnicamente para evitar penalizaciones en la evaluación.

## 5. Próximos Desafíos Técnicos (Prioridades)

### A. Migración a Contenedores (EKS/Fargate)

Para mejorar la eficiencia y eliminar la gestión manual de RAM de las máquinas virtuales (EC2), se debe migrar el backend a **AWS Fargate** o **EKS (Elastic Kubernetes Service)**.

### B. Optimización del Frontend

El profesor cuestiona el uso de S3 como servicio de pago adicional.

* **Opción sugerida**: Contenerizar el Frontend (Nginx) y desplegarlo dentro del mismo clúster que el Backend para aprovechar la capacidad de cómputo existente.

### C. Pipeline de CI/CD (Obligatorio)

Implementar un flujo automatizado que incluya:

* **Calidad de Código**: Integración con SonarQube o pruebas de testing.
* **Seguridad de Infraestructura**: Escaneo de seguridad del código Terraform usando **Checkov**.
* **Despliegue Automatizado**: Uso de Jenkins o GitHub Actions para despliegues basados en Pull Requests aprobados hacia la rama `main`.

## 6. Instrucciones para Copilot

1. **Analiza** los archivos `.tf` existentes para proponer la migración de `aws_instance` a servicios de contenedores (ECS/Fargate).
2. **Propón** una estructura de carpetas que separe ambientes (dev/prod) mediante variables de entorno.
3. **Genera** archivos de configuración para un Pipeline de CI/CD (ej. `.github/workflows/terraform.yml`) que incluya un paso de seguridad con Checkov.
4. **Refactoriza** el código para eliminar cualquier credencial explícita.
