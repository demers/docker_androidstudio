# docker_androidstudio

Démarrer Android Studio dans un conteneur Docker

# Démarrage

Pour construire l'image et le conteneur, on tape:

```
cd /..../docker_androidstudio/
docker-compose build
docker-compose up -d

ssh -X ubuntu@localhost
ubuntu@localhost's password:
```

Le mot de passe est *ubuntu*

Le paramètre "-X" permet de créer un pont X11 pour l'affichage de Atom sur le
poste hôte bien que Atom s'exécute dans le conteneur.

