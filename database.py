import pymysql.cursors
from datetime import datetime

connection = pymysql.connect(
    host="localhost", user="root", password="Imparfait2017", db="testdb", autocommit=True)
cursor = connection.cursor()

# Base de données globales
def select_especes(espece=None, pays=None, continent=None):


    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    if espece is None and pays is None and continent is None:
        request = """SELECT * FROM Espece;"""
    if espece is not None and pays is None and continent is None:
        request = """SELECT * FROM espece WHERE espece LIKE '%{}%';""".format(espece)
    elif continent is not None and espece is not None:
        request = """SELECT DISTINCT E.* FROM Espece E, ENTREPOSER E1, Pays P 
        WHERE E.espece=E1.espece AND E1.espece LIKE '%{}%' AND E1.pays=P.pays AND P.continent="{}";""".format(espece, continent)

    if continent is not None and espece is None and pays is None:
        request = """SELECT DISTINICT E.* FROM Espece E, ENTREPOSER E1, Pays P 
        WHERE E.espece=E1.espece AND E1.pays=P.pays AND P.continent LIKE '{}';"""\
            .format(continent)



    cur.execute(request)
    especes = cur.fetchall()
    return especes



#Filtrer les pays d'un comtinent
def select_pays_de_continent(continent):
    request = """SELECT pays FROM Pays WHERE continent={};""".format(continent)
    cursor.execute(request)
    pays = cursor.fetchall()
    return pays

def select_pays():
    request = """ SELECT * FROM Pays;"""
    cursor.execute(request)
    retraits = cursor.fetchall()
    return retraits

def select_continents():
    request = """SELECT * FROM Continent;"""
    cursor.execute(request)
    retraits = cursor.fetchall()
    return retraits


# Tri déposants


#select_déposant
def select_deposants(ville=None, tri=None, nom=None):
    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    base_request = """SELECT nom, ville, nombreEspeceDepose, nombreGenreDepose,  nombreGraineDepose,
     courriel FROM Deposant"""
    if ville == "" or ville is None:
        request = base_request
        if nom is not None and nom != "":
            request += """ WHERE nom LIKE '%{}%'""".format(nom)
        if tri != "" and tri is not None:
            request += """ ORDER BY {} DESC""".format(tri)

    else:
        request = base_request + """ WHERE ville LIKE '%{}%'""".format(ville)
        if nom is not None and nom != "":
            request += """ AND nom LIKE '%{}%'""".format(nom)
        if tri is not None and tri != "":
            request += """ ORDER BY {} DESC""".format(tri)
    if(ville is None or ville == "") and (tri is None or tri == "") and (nom is None or nom == ""):
        request = base_request
    request += ";"
    cur.execute(request)
    deposants = cur.fetchall()
    return deposants

#Vues utilisateur
def create_vue_mesDepots(id):
    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    request = """SELECT """


#Vue déposant
#L'argument CodeDeposant doit etre passé en string

def get_user_infos(codeDeposant):
    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    request = """ SELECT codeDeposant , nom, ville FROM Deposant WHERE codeDeposant = {};"""\
        .format(codeDeposant)
    cur.execute(request)
    user_infos = cur.fetchall()
    return user_infos

def select_depots(codeDeposant, espece=None, tri=None):
    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    base_request = """SELECT espece, quantite, nombreBoites, dateArriver FROM Deposer WHERE codeDeposant LIKE '{}'"""\
        .format(codeDeposant)
    if espece is not None and espece != " ":
        request = base_request + """ AND espece LIKE '%{}%'""".format(espece)
        if tri is not None and tri != "":
            request += """ ORDER BY {} DESC""".format(tri)
    if espece is None or espece == "":
        request = base_request
        if tri is not None and tri != "":
            request += """ ORDER BY {} DESC""".format(tri)
    request += ";"
    cur.execute(request)
    depots = cur.fetchall()
    return depots

def select_espece_deposees(codeDeposant):
    request = """SELECT DISTINCT espece FROM Deposer WHERE codeDeposant={};""".format(codeDeposant)
    cursor.execute(request)
    espece_deposees = cursor.fetchall()
    return espece_deposees

def select_retraits(codeDeposant):
    request = """SELECT espece, quantite, nombreBoites, dateSortie FROM Retirer WHERE codeDeposant LIKE '{}';""".format(codeDeposant)
    cursor.execute(request)
    retraits = cursor.fetchall()
    return retraits




def select_deposant(nom):
    request = """SELECT * FROM Deposant WHERE nom LIKE '%{}%';""".format(nom)
    cursor.execute(request)
    espece_deposees = cursor.fetchall()
    return espece_deposees

def select_deposants_de_espece(espece):
    request = """SELECT DISTINCT D.nom FROM Deposant D, Deposer D2, Espece E 
     WHERE D2.codeDeposant=D.codeDeposant and D2.espece;"""
    cursor.execute(request)
    espece_deposees = cursor.fetchall()
    return espece_deposees

def deposer (codeDeposant, espece, quantite, nombreBoite):
    request = """INSERT INTO Deposant VALUES ({}, {}, {}, {}, {});""".format(espece, codeDeposant, quantite,
                                                                          nombreBoite, datetime.now())
    cursor.execute(request)
    return True


def insert_deposant(nom,courriel, ville):
    request = """SELECT MAX(codeDeposant) FROM Deposant;"""
    cursor.execute(request)
    i = cursor.fetchall()
    codeDeposant = i[0][0] + 1
    request = """INSERT INTO Deposant(nom, courriel, codeDeposant, ville) VALUES({}, {}, {});""".format(nom, courriel,
                    codeDeposant, ville)
    cursor.execute(request)
    return True

def select_all_depots():
    request = """SELECT * FROM Deposer;"""
    cursor.execute(request)
    depots = cursor.fetchall()
    return depots




