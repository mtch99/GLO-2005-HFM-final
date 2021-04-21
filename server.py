from flask import Flask, render_template, request, redirect, jsonify, json, url_for, session
from flask_table import Table, Col
import string
import random as rd
import pymysql, pymysql.cursors
import database
import os


app = Flask(__name__)
app.secret_key = 'BAD_SECRET_KEY'

class EspeceTable(Table):
    classes = ['table']
    espece = Col('Espèce')
    nomVernaculaire = Col('Nom Vernaculaire')
    nombreDeposant = Col('Nombre de déposants')
    quantite = Col("Quantité")

class DepotTable(Table):
    classes = ['table']
    espece = Col("Espèce")
    quantite = Col("Quantité")
    nombreBoites = Col("Nombre de Boites")
    dateArriver = Col("Date de dépôt")

class DeposantTable(Table):
    classes = ['table']
    nom = Col('Nom')
    ville = Col('ville')
    nombreEspeceDepose = Col("Nombre d'espèces")
    nombreGenreDepose = Col(' Nombre de genres')
    nombreGraineDepose = Col('Nombre de graines')
    courriel = Col('Courriel')

class RetraitTable(Table):
    classes = Col('table')
    espece = Col('espece')
    quantite = Col('Quantite retirée')
    nombreBoites = Col('Nombre de boites retirées')
    dateSortie = Col('Date de sortie')





@app.route("/")
def pageAccueil():
    letters = string.ascii_letters
    #global sessionid=''.join(rd.choice(letters) for i in range(10))
    return render_template('PageAccueil.html')


@app.route("/PageConnexion", methods=['POST'])
def pageConnexionl():
    return render_template('PageConnexion.html')

@app.route("/connexion", methods=['POST'])
def connexion():
    #TODO
    courriel = request.form.get('id')
    motPasse = request.form.get('motPasse')
    conn = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb')
    cmd = """SELECT motDePasse FROM Utilisateur WHERE courriel='{}';"""\
        .format(courriel)
    cur = conn.cursor()
    cur.execute(cmd)
    passeVrai = cur.fetchone()
    if (passeVrai is not None) and (motPasse == passeVrai[0]):
        conn = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb')
        cmd = """SELECT D.codeDeposant FROM Utilisateur U, Deposant D 
        WHERE U.courriel = D.courriel AND U.courriel LIKE '{}';""" \
            .format(courriel)
        cur = conn.cursor()
        cur.execute(cmd)
        id = cur.fetchall()
        dict = id[0]
        identifiant = dict[0]
        print(identifiant)
        session["ID"] = identifiant
        print(session["ID"])
        return redirect(url_for("mesDepots", id=identifiant))
    else:
        return render_template("PageConnexion.html", text="Mot de passe ou courriel non valides")

@app.route("/mesDepots/<id>")
@app.route("/mesDepots/<id>/<table>")
def mesDepots(id, table=None):
        if table is not None:
            print(table)
            return render_template("MesDepots.html", table=table)
        depots = database.select_depots(id)
        items = []

        for depot in depots:
            items.append(dict(espece=depot["espece"], quantite=depot["quantite"], nombreBoites=depot["nombreBoites"],
                              dateArriver=depot["dateArriver"]))
        table = DepotTable(items)
        return render_template("MesDepots.html", table=table)

@app.route("/mesDepots/goToRetraits")
def gotoRetrait():
    print("yes")
    id = session["ID"]
    return (redirect(url_for("mesRetraits", id=id)))


@app.route("/mesDepots/goToDepots")
def goToDepot():
    print("yes")
    id = session["ID"]
    print(id)
    return redirect(url_for("mesDepots", id=id))

@app.route("/mesDepots/triDepots", methods=['POST', 'GET'])
def tri_depots():
    id = session["ID"]
    triInput = request.form.get('triInput')
    especeInput = request.form.get('especeInput')
    depots = database.select_depots(codeDeposant=id, espece=especeInput, tri=triInput)
    items = []
    for depot in depots:
        items.append(dict(espece=depot["espece"], quantite=depot["quantite"], nombreBoites=depot["nombreBoites"],
                          dateArriver=depot["dateArriver"]))
    tables = DepotTable(items)
    print(tables)
    return redirect(url_for("mesDepots", id=id, table=tables))


@app.route("/mesDepots/goToRetraits")
def goToDRetraits():
    print("yes")
    id = session["ID"]
    print(id)
    return redirect(url_for("mesRetraits", id=id))

@app.route("/mesRetraits/<id>")
@app.route("/mesRetraits/<id>/<table>")
def mesRetraits(id, table=None):
    print("id")
    if table is not None:
        return render_template("MesRetraits.html", table=table)
    items = []
    retraits = database.select_retraits(id)
    for retrait in retraits:
        print(retrait)
        items.append(dict(espece=retrait["espece"], quantite=retrait["quantite"], nombreBoites=retrait["nombreBoite"],
                          dateSortie=retrait["dateSortie"]))
    table = RetraitTable(items)
    return render_template("MesRetraits.html", table=table)

@app.route("/mesRetraits/goToDepots")
def gotoDepots():
    print("yes")
    id = session["ID"]
    print(id)
    return redirect(url_for("mesDepots", id=id))

@app.route("/mesRetraits/goToRetraits")
def gotoRetraits():
    print("yes")
    id = session["ID"]
    print(id)
    return redirect(url_for("mesRetraits", id=id))



@app.route("/BaseDeDonnee")
def baseDeDonnee():
    print(1)
    items = []
    especes = database.select_especes()
    for espece in especes:
        items.append(dict(espece=espece["espece"], nomVernaculaire=espece["nomVernaculaire"],
                          nombreDeposant=espece["nombreDeposant"], quantite=espece["quantite"]))

    table = EspeceTable(items)
    return render_template('espece_global.html', table = table)

@app.route("/espece_global", methods=['GET'])
def espece_globale():
    items = []
    especes = database.select_especes()

    for espece in especes:
        items.append(dict(espece=espece["espece"], nomVernaculaire=espece["nomVernaculaire"],
                          nombreDeposant=espece["nombreDeposant"], quantite=espece["quantite"]))

    table = EspeceTable(items)
    return render_template("espece_global.html", table=table)


@app.route("/triEspece", methods=['POST', 'GET'])
def triEspece():
    items = []
    espece = request.form.get('especeInput')
    continent = request.form.get('continentInput')
    if continent != "" and espece is None:
        print(espece)
        especes = database.select_especes(continent=continent)

    if espece is not None and continent == "":
        print(espece)
        especes = database.select_especes(espece=espece)

    if espece is not None and continent != "":
        print(espece)
        especes = database.select_especes(espece=espece, continent=continent)

    print(especes)

    for espece in especes:
        items.append(dict(espece=espece["espece"], nomVernaculaire=espece["nomVernaculaire"],
                          nombreDeposant=espece["nombreDeposant"], quantite=espece["quantite"]))
    table = EspeceTable(items)

    return render_template("espece_global.html", table=table)


@app.route("/deposantGlobal")
def deposantGlobal():
    items = []
    deposants = database.select_deposants()
    for deposant in deposants:
        items.append(dict(nom=deposant["nom"], ville=deposant["ville"],
                          nombreEspeceDepose=deposant["nombreEspeceDepose"],
                          nombreGraineDepose=deposant["nombreGraineDepose"],
                          nombreGenreDepose=deposant["nombreGenreDepose"],
                          courriel=deposant["courriel"]))
    table = DeposantTable(items)
    return render_template("deposantGlobal.html", table=table)

@app.route("/triDeposant", methods=['GET', 'POST'])
def triDeposant():
    items = []
    nom = request.form.get('nomInput')
    ville = request.form.get('villeInput')
    tri = request.form.get('triInput')
    deposants = database.select_deposants(nom=nom, ville=ville, tri=tri)
    for deposant in deposants:
        items.append(dict(nom=deposant["nom"], ville=deposant["ville"],
                          nombreEspeceDepose=deposant["nombreEspeceDepose"],
                          nombreGraineDepose=deposant["nombreGraineDepose"],
                          nombreGenreDepose=deposant["nombreGenreDepose"],
                          courriel=deposant["courriel"]))
    table = DeposantTable(items)
    return render_template("deposantGlobal.html", table=table)


@app.route("/getDeposant")
def getDeposant():
    return None

@app.route("/Pays")
def paysGlobal():
    return render_template("pays.html")

@app.route("/Continent")
def continentGlobal():
    return render_template("continentGlobal.html")










@app .route("/DepotRetrait", methods = ['POST'])
def DepotRetrait():
    items = []
    especes = database.all_depots()
    for espece in especes:
        items.append(dict(espece=espece[0], nomVernaculaire=espece[1], nombreDeposant=espece[2], quantite=espece[3]))

    table = EspeceTable(items)
    return render_template('BaseDeDonnee.html', table = table)

    return render_template("MesDepots.html")


if __name__ == "__main__":
    app.run()


@app.route("/select_Pays_de_continent/")
@app.route("/select_Pays_de_continent/<continent>", methods=['GET', 'POST'])
def select_pays_de_continent(continent=None):
    response = {}
    query_answer = database.select_pays_de_continent(continent)
    for id in query_answer:
        response[id[0]] = {}
        (response[id[0]])["pays"] = id[0]
    return response

































