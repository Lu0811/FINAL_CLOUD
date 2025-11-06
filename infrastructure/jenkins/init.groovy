#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Crear usuario admin
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')
instance.setSecurityRealm(hudsonRealm)

// Dar acceso completo a usuarios autenticados
def strategy = new hudson.security.GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, 'admin')
instance.setAuthorizationStrategy(strategy)

// Guardar configuración
instance.save()

println "✅ Usuario admin creado con contraseña: admin123"
