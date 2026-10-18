# Lab Valkey avec Docker Compose : apprendre un magasin clé-valeur compatible Redis, l’expiration, les listes, les hachages et les compteurs

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-valkey/actions/workflows/check.yml)

Un **lab Valkey** prêt à l’emploi pour la classe, issu de la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning), où les écoles et les établissements donnent à chaque élève ses propres bases de données, conteneurs et terminal dans le navigateur. Chaque élève reçoit son propre **Valkey, le magasin clé-valeur open source qui comprend les mêmes commandes que Redis**, pour apprendre **SET et GET, les clés qui expirent, les listes, les hachages et les compteurs**, et pour voir ce que fait un magasin qui garde ses données en mémoire lorsqu’on l’arrête puis qu’on le redémarre. Rien n’est installé sur la machine de l’élève et rien de ce qu’il tape ne peut toucher quelqu’un d’autre.

Tout tient dans un seul fichier `docker-compose`, `compose.yaml`, qui fonctionne de la même façon sur votre propre machine et sur la plateforme, où chaque élève obtient une copie privée sans aucun accès à internet.

## Ce que vous y trouvez

| Service | Image | Mémoire | Ce que c’est |
| --- | --- | --- | --- |
| `valkey` | [`valkey/valkey:8.1.10-alpine`](https://hub.docker.com/r/valkey/valkey) | 64 Mo | le magasin clé-valeur, sur le port 6379, avec un fichier en ajout seul dans un volume nommé |

Il démarre en bonne santé en trois secondes environ et utilise à peu près 4 Mo au repos. Il s’exécute sous un utilisateur sans privilèges, et la quantité maximale qu’il accepte de contenir est de 32 Mo, au-delà de laquelle une écriture est refusée au lieu que le service soit tué. Il n’y a pas de mot de passe, car rien d’extérieur à la copie ne peut l’atteindre.

L’image est un programme tiers, exécuté sans modification à partir de l’image publique du projet et figé sur une version (jamais `latest`), de sorte que le lab ne change pas sous les pieds d’une classe d’une leçon à l’autre. Rien n’est construit ici et rien de ce dépôt n’y est distribué.

**Pourquoi Valkey et pas Redis.** Valkey est le fork de Redis 7.2 sous licence BSD-3-Clause de la Linux Foundation, et il répond aux mêmes commandes : ce que l’élève apprend ici fonctionne donc sur Redis et sur la plupart des services qui proposent un magasin compatible Redis. Redis 8 et les versions suivantes sont sous une autre licence (AGPL ou RSAL), c’est pourquoi ce lab utilise Valkey.

## L’utiliser sur la plateforme

La [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) donne à chaque élève sa propre copie d’un lab, dans le navigateur, avec un terminal à côté.

**Pour l’essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/fr/container), trouvez ce lab dans **Laboratoires d’exemple** et appuyez sur Démarrer, puis sur **Ouvrir le terminal**. Aucun compte n’est nécessaire pour en essayer un. Le lab n’a pas de page web, tout se tape donc dans le terminal.

**Pour le donner comme travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **Dans un dépôt GitHub**.
2. Indiquez `https://github.com/mitsurutech/lab-valkey` avec la branche `main`. Le fichier compose est celui par défaut, `compose.yaml`. Faites d’abord un fork du dépôt si vous voulez modifier le fichier.
3. Publiez. La copie de chaque élève part du commit que vous avez publié, de sorte qu’une modification ultérieure ici ne change pas un lab déjà donné.
4. Précisez dans la tâche ce qu’il faut rendre (voir [Pour les enseignants](#pour-les-enseignants)), puis distribuez-la comme n’importe quelle autre tâche.

La [page de ce lab](https://mitsurutech.co.uk/fr/help/lab-valkey) et le [guide des labs de conteneurs](https://mitsurutech.co.uk/fr/help/labs) du manuel couvrent le reste : ce qu’un fichier compose peut contenir, la mémoire dont dispose une copie, et comment un enseignant ouvre, suit et note la copie d’un élève. Une leçon de base gratuite, **Valkey Basics**, est aussi travaillée dans ce lab. Pas encore de compte d’établissement ? [La première année est gratuite](https://mitsurutech.co.uk/fr/pricing) jusqu’à 50 élèves, et [l’inscription](https://mitsurutech.co.uk/fr/signup) ne demande qu’une adresse e-mail.

## Le terminal n’a pas de valkey-cli

Le terminal de la plateforme contient `psql`, `mariadb`, `curl`, `git` et `nc`, mais pas de client Valkey. Ce n’est pas un obstacle, car Valkey accepte une commande sous forme d’une ligne de texte brut. Cette ligne crée une fonction appelée `v` qui envoie ses mots au magasin et affiche la réponse :

```bash
v() ( printf '%s\r\n' "$*" | nc -w 1 valkey 6379 )
```

Puis :

```text
$ v SET greeting hello
+OK
$ v GET greeting
$5
hello
$ v GET missing
$-1
```

Les réponses sont le vrai protocole, **RESP** : `+` est un court mot de succès, `$5` annonce que la ligne suivante est un texte de cinq octets, `$-1` signifie « rien ici », `:3` est un nombre et `*3` annonce que trois éléments suivent. Vous pouvez aussi lancer `nc valkey 6379` et taper des commandes directement au serveur, une par ligne. Sur votre propre machine, vous pouvez utiliser `valkey-cli` ou `redis-cli` à la place, voir ci-dessous.

## L’exécuter sur votre propre machine

Il vous faut Docker avec le plugin Compose. Le premier démarrage télécharge l’image.

```bash
docker compose -f compose.yaml -f local.yaml up
```

`local.yaml` publie le port 6379 sur `127.0.0.1` uniquement, de sorte que le lab n’est accessible que depuis votre ordinateur. Connectez-vous avec `valkey-cli -p 6379` ou `redis-cli -p 6379`, ou avec `nc` comme ci-dessus. Arrêtez-le avec `Ctrl-C` et supprimez-le, données comprises, avec `docker compose -f compose.yaml -f local.yaml down -v`.

## Pas à pas

1. **Stocker et récupérer.** `v SET greeting hello`, puis `v GET greeting`.
2. **Faire expirer une clé.** `v SET code 1234 EX 5` la conserve cinq secondes. `v TTL code` décompte, et passé ces cinq secondes `v GET code` répond `$-1`.
3. **Une liste.** `v RPUSH tasks wake eat code` répond `:3`, et `v LRANGE tasks 0 -1` relit les trois éléments dans l’ordre.
4. **Un hachage.** `v HSET user:1 name Ada born 1815` répond `:2`, et `v HGETALL user:1` affiche les noms des champs et leurs valeurs.
5. **Un compteur.** `v INCR visits` répond `:1`, puis `:2` la fois suivante. C’est le magasin qui additionne, de sorte que deux clients en même temps ne perdent jamais un décompte.
6. **Voir ce qui dure.** Arrêtez le lab puis redémarrez-le : `v GET greeting` vaut toujours `hello`. Le magasin garde tout en mémoire, ce qui le rend rapide, et consigne chaque écriture dans un fichier en ajout seul d’un volume nommé, ce qui lui permet de reconstruire sa mémoire au démarrage. `v CONFIG GET appendonly` répond `yes`. La clé expirée n’est pas revenue.

## Pour les enseignants

Rien dans ce lab n’est noté automatiquement. L’élève rend des preuves et vous les notez, comme pour n’importe quel autre lab.

**Demandez les réponses d’une courte session à lui :** une clé avec une expiration et `TTL` qui décompte, une liste, un hachage et un compteur, avec une phrase sur ce que l’expiration a fait, et une sur ce qui était encore là après l’arrêt et le redémarrage du lab, et pourquoi. La dernière montre si l’élève a compris la différence entre la mémoire et un fichier sur disque.

**Sa place dans un cursus.** Il convient à une introduction aux bases de données et aux magasins de données, où un magasin clé-valeur est le plus simple des types non relationnels, et au développement web, où les sessions, les caches et les compteurs sont les usages d’un tel magasin. Vérifiez l’unité de votre propre organisme de certification pour la formulation exacte ; aucune n’est citée ici.

**Qui voit quoi.** Une copie est privée pour l’élève qui l’a démarrée. Un membre du personnel qui enseigne le module peut l’ouvrir pour voir ce que l’élève a fait, et l’ouverture du travail d’un élève est inscrite dans le journal d’accès, que l’élève peut lire.

## Ce qui ne fonctionne pas dans un lab

Le lab n’a aucun accès à internet, pas de mot de passe sur le magasin (rien d’autre ne peut l’atteindre) et pas de page web. D’autres fonctions de Valkey, comme la réplication vers un second serveur, demandent plus d’un service et ne font pas partie de ce lab. Le magasin dispose de 64 Mo et refuse les écritures au-delà de 32 Mo de données.

## Dépannage

- **Une commande n’affiche rien.** Définissez d’abord la fonction `v`, dans le même terminal. Si le magasin n’a pas démarré, attendez que le lab indique qu’il est en marche.
- **Une réponse ressemble à `$5`.** C’est la longueur de la ligne suivante, pas une erreur : lisez la ligne qui suit.
- **Sur votre propre machine, le port 6379 est déjà utilisé.** Changez le nombre de gauche dans `local.yaml`, par exemple `127.0.0.1:6380:6379`.

## Vérifier le lab

`test/check.sh` démarre le lab comme le fait l’exécuteur de la plateforme pour chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, des limites de mémoire et aucun accès à internet), puis vérifie depuis l’intérieur de son réseau ce que cette page promet : les commandes ci-dessus répondent comme indiqué, une expiration arrive à son terme, et une clé écrite avant un arrêt est toujours là après le démarrage. Il demande Docker et s’exécute à chaque push, ce qui correspond au badge en haut de la page.

```bash
test/check.sh
```

## Versions et licences

[Valkey](https://valkey.io) est sous licence BSD-3-Clause. L’image est `valkey/valkey:8.1.10-alpine`, exécutée sans modification et non distribuée par nous.

L’application qu’elle contient a la licence de son propre projet, indiquée ci-dessus.

## Licence

Cette œuvre est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Vous pouvez la partager et l’adapter pour apprendre et enseigner, à condition de citer Mitsuru Technologies Ltd, de ne pas l’utiliser commercialement et de partager tout ce que vous en tirez sous la même licence. Le texte complet est dans le fichier `LICENSE`.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk) pour la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labs de conteneurs, des applications web déployées depuis GitHub et des quiz qui se corrigent seuls. Essayez du code sans compte dans le [bac à sable](https://mitsurutech.co.uk/fr/playground). Tous les labs sont listés dans le [manuel](https://mitsurutech.co.uk/fr/help/labs).

D’autres labs du même éditeur : [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa) et [lab-sample](https://github.com/mitsurutech/lab-sample).
