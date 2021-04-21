
function fetchEspeces() {
    getUrl = "BaseDeDonnee"

    fetch(getUrl).then(function(response) {
        return response.json()
    }).then(function(data) {
        todos = data.todos;
        ids = data.ids;

        for(let todo of todos) {
            displayNewTodo(todo);
        }

        fillSelect(ids)
    })
}

function filterFunction() {
  var input, filter, ul, li, a, i;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  div = document.getElementById("myDropdown");
  a = div.getElementsByTagName("a");
  for (i = 0; i < a.length; i++) {
    txtValue = a[i].textContent || a[i].innerText;
    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      a[i].style.display = "";
    } else {
      a[i].style.display = "none";
    }
  }
}

function get_pays_de_continent(){
    const continent = document.getElementById("ContinentList").value
    console.log(continent)
    const getUrl = "GLO-2005-HFM-main-3/server.py/select_Pays_de_continent/" + continent
    console.log(getUrl)
    fetch(getUrl).then(function(response) {
        return response.json()
    }).then(function(data) {
        const liste_pays = [];
        for (pays in data){
            liste_pays.push(pays[0])
        }
        addPaysInputBox(liste_pays)
    })
}

function addPaysInputBox(liste_pays){
    alert(4)
    form = document.getElementById("form")
    paysBox=document.createElement("select")
    paysBox.id = "paysInput"
    continentInput = document.getElementById("ContinentList").value()
    form.appendChild(paysBox)
    all_option = document.createElement("option")
    all_option.disabled
    all_option.defaultSelected
    all_option.value = ""
    paysBox.appendChild(all_option)
    if(continentInput!=""){
        // Identifier le main et creer le conteneur de la dropdown list
        form = document.getElementById("form")
        ListContainer = document.createElement("input" )
        ListContainer.list = 'paysListe'
        ListContainer.placeholder = 'Pays'
        //ListContainer.addEventListener()
        main.appendChild(ListContainer)

        // Créer la dataliste
        datalist = document.createElement("datalist")
        datalist.id = 'ListContainer'
        // Ajouter au conteneur
        ListContainer.appendChild(datalist)
    }
}

