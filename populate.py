import random as rd
import pymysql, pymysql.cursors
import xlrd
import os
import pandas as pd
import numpy as np
from pandas.io import sql
from sqlalchemy import create_engine
import sqlalchemy
import time

initTime = time.time()

dicoRenameSeedParContinent = {'Institute name': 'nom', 'Institute code': 'codeDeposant',
                              'Institute acronym': 'courriel',
                              'Accession number': 'idCase', 'Full scientific name': 'nomVernaculaire',
                              'Species': 'espece',
                              'Country of collection': 'pays'}


def insertX(df, tableSql):
    df = df.drop_duplicates()
    print("\nAdding....." + str(len(df)) + ".....tuples à la table : " + tableSql + " ...")
    tupleFait = 0
    try:
        df.to_sql(con=conn, name=tableSql, if_exists='append', index=False, chunksize=20)
        tupleFait += 20
    except sqlalchemy.exc.IntegrityError as e:
        print("SKIP : " + str(e.orig))
        for i in range(tupleFait, len(df)):
            try:
                df.iloc[i:i + 1].to_sql(con=conn, name=tableSql, if_exists='append', index=False)
            except sqlalchemy.exc.IntegrityError as e2:
                pass
    except ValueError as vx:
        print(vx)
    except Exception as ex:
        print(ex)


def insertUsingProcedure(df, tableSql):
    df = df.drop_duplicates()
    print("\nAdding....." + str(len(df)) + "..... avec : " + tableSql + " ...")
    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    start = time.time()
    for i in range(len(df)):
        try:
            row = df.iloc[i]
            cmd = 'CALL DeposerRetirerSansUpdateQuantite("{}","{}","{}","{}", {}, "{}", "{}", {});'.format(
                row['espece'], row['nomVernaculaire'], row['genre'], row['nomVernaculaire'],
                row['quantite'], row['codeDeposant'], row['pays'], row['boite'])

            cur.execute(cmd)
            if (len(df) > 10):
                if (i % int(0.2 * len(df)) == 0):
                    print(str((i / int(0.2 * len(df))) * 10) + " %", end='\r')

        except sqlalchemy.exc.IntegrityError as e:
            pass
        except ValueError as vx:
            print(vx)
        except Exception as ex:
            print(ex)
    conne.commit()
    print("took : {:10.3f} seconds".format(time.time() - start))

    conne = pymysql.connect(host='localhost', user='root', password='Imparfait2017', db='testdb',
                            cursorclass=pymysql.cursors.DictCursor)
    cur = conne.cursor()
    start = time.time()

    dfPaysUpdate = df[['pays']]
    dfPaysUpdate = dfPaysUpdate.drop_duplicates()
    dfDeposantUpdated = df[['codeDeposant']]
    dfDeposantUpdated = dfDeposantUpdated.drop_duplicates()

    print("\nUpdating quantite sur .... %s pays" % len(dfPaysUpdate))
    for i in range(len(dfPaysUpdate)):
        try:
            row = dfPaysUpdate.iloc[i]
            cmd = 'CALL UpdateQuantitePays("{}");'.format(row['pays'])

            cur.execute(cmd)
            if (len(dfPaysUpdate) > 10):
                if (i % int(0.2 * len(dfPaysUpdate)) == 0):
                    print(str((i / int(0.2 * len(dfPaysUpdate))) * 10) + " %", end='\r')

        except sqlalchemy.exc.IntegrityError as e:
            pass
        except ValueError as vx:
            print(vx)
        except Exception as ex:
            print(ex)
    print("Updating quantite sur .... %s déposant" % len(dfDeposantUpdated))
    for i in range(len(dfDeposantUpdated)):
        try:
            row = dfDeposantUpdated.iloc[i]
            cmd = 'CALL UpdateQuantiteDeposant("{}");'.format(row['codeDeposant'])

            cur.execute(cmd)
            if (len(dfDeposantUpdated) > 10):
                if (i % int(0.2 * len(dfDeposantUpdated)) == 0):
                    print(str((i / int(0.2 * len(dfDeposantUpdated))) * 10) + " %", end='\r')

        except sqlalchemy.exc.IntegrityError as e:
            pass
        except ValueError as vx:
            print(vx)
        except Exception as ex:
            print(ex)
    conne.commit()

    print("took : {:10.3f} seconds".format(time.time() - start))


sqlEngine = create_engine('mysql+pymysql://root:Imparfait2017@localhost/testdb', pool_recycle=3600)
conn = sqlEngine.connect()

# Continent
dfContinents = pd.DataFrame({'nomContinent': ['Africa', 'Antarctica', 'Asia', 'Europe',
                                              'North America', 'South America', 'Oceania', 'Unknown']})
insertX(dfContinents, 'Continent')

directoryExcel = os.path.join(os.path.dirname(__file__), "donneeExcel")

# Deposant + utilisateur
dfDeposant = pd.read_excel(os.path.join(os.path.dirname(__file__), "donneeExcel", "deposant.xlsx"), engine='openpyxl')
dfDeposant = dfDeposant[['Depositor name', 'Institute code', 'Country']].rename(
         columns={'Depositor name': 'nom', 'Institute code': 'codeDeposant', 'Country': 'ville'})
courrielCol = dfDeposant.apply(lambda row: row.codeDeposant + "@gmail.com", axis=1)
dfDeposant = dfDeposant.assign(courriel=courrielCol.values)
dfDeposant.loc[18, 'codeDeposant'] = "USA105"

dfUtilisateur = dfDeposant[['courriel']]
dfUtilisateur = dfUtilisateur.assign(motDePasse=1234)
insertX(dfUtilisateur, 'Utilisateur')
insertX(dfDeposant, 'Deposant')

# provenirDeposant
dfProvenirDeposant = dfDeposant[['ville', 'codeDeposant']].rename(columns={'ville': 'pays'})
insertX(dfProvenirDeposant, 'ProvenirDeposant')

# Préparation pour utiliser Procedure : Deposer/retirer
dfGenre = pd.read_excel(os.path.join(os.path.dirname(__file__), "donneeExcel", "genre.xlsx"), engine='openpyxl')
dfGenre = dfGenre[['Genus', 'Vernacular name']].rename(columns={'Genus': 'genre', 'Vernacular name': 'nomVernaculaire'})
dfEspesce = pd.read_excel(os.path.join(os.path.dirname(__file__), "donneeExcel", "espece.xlsx"), engine='openpyxl')
dfEspesce = dfEspesce[['Species']].rename(columns={'Species': 'espece'})
relieEspece = dfEspesce.apply(lambda x: x.espece.split(" ")[0], axis=1)
dfEspesce = dfEspesce.assign(genre=relieEspece.values)

dfEspesceGenre = pd.merge(dfEspesce, dfGenre, on='genre')

onlySeedExcel = [f for f in os.listdir(directoryExcel) if f.endswith(".xlsx") and "seed" in f]
for f in onlySeedExcel:
    continent = f.split('_')[1]
    print("\nReading file : " + f + "\n----------------------------------------------------------------")

    df1 = pd.read_excel(
        os.path.join(os.path.dirname(__file__), "donneeExcel", f), engine='openpyxl')

    df1.rename(columns=dicoRenameSeedParContinent, inplace=True)

    # Pays 
    dfPays = df1[['pays']]
    dfPays = dfPays.assign(continent=continent)
    insertX(dfPays, 'Pays')

    # Entreposer
    dfEntreposer = df1[['espece', 'codeDeposant', 'pays']]
    date = dfEntreposer.apply(
        lambda x: str(rd.randint(2010, 2021)) + "-" + str(rd.randint(1, 12)) + "-" + str(rd.randint(1, 28)), axis=1)
    dfEntreposer = dfEntreposer.assign(dateEntreposage=date.values)
    dfEntreposer['quantite'] = np.random.randint(1, 80, dfEntreposer.shape[0])
    boite = dfEntreposer.apply(lambda x: 1 if x.quantite <= 30 else (2 if (x.quantite <= 60) else 3), axis=1)
    dfEntreposer = dfEntreposer.assign(boite=boite.values)

    dfDeposer = pd.merge(dfEntreposer, dfEspesceGenre, on='espece')
    dfDeposer = dfDeposer.drop_duplicates(subset=['codeDeposant', 'espece'], keep='last')
    dfDeposer = dfDeposer.reset_index()
    dfDeposer = dfDeposer.drop(['index'], axis=1)

    insertUsingProcedure(dfDeposer, 'DeposerRetirer')

print("took overall {:10.3f} seconds".format(time.time() - initTime))
