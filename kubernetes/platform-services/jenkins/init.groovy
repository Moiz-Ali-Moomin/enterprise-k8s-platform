import jenkins.model.*
import hudson.security.*
import jenkins.install.*
import hudson.util.*

// 1. Create Admin User
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()

// 2. Install Plugins
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()
def plugins = ["git", "workflow-aggregator", "kubernetes", "docker-workflow", "sonar", "configuration-as-code", "blueocean", "generic-webhook-trigger"]

plugins.each {
  if (!pm.getPlugin(it)) {
    def plugin = uc.getPlugin(it)
    if (plugin) {
      plugin.deploy()
    }
  }
}
instance.save()

// 3. Generate API Token for Admin (Bypass CSRF)
import jenkins.security.*
def user = hudson.model.User.get('admin')
def tokenProperty = user.getProperty(ApiTokenProperty.class)
if (tokenProperty == null) {
    tokenProperty = new ApiTokenProperty()
    user.addProperty(tokenProperty)
}
def tokenResult = tokenProperty.tokenStore.generateNewToken('automation-token')
user.save()
new File('/var/jenkins_home/admin-token').text = tokenResult.plainValue
