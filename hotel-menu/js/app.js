const dataPath = "data/menu.json";

const state = {
  data: null,
  category: "all",
  search: "",
  favorites: new Set(),
  activeView: "menu",
  cart: new Map(),
};

const refs = {
  hotelName: document.getElementById("hotel-name"),
  hotelTagline: document.getElementById("hotel-tagline"),
  hotelHours: document.getElementById("hotel-hours"),
  categoryChips: document.getElementById("category-chips"),
  highlights: document.getElementById("highlights"),
  menuList: document.getElementById("menu-list"),
  favoritesList: document.getElementById("favorites-list"),
  resultsCount: document.getElementById("results-count"),
  search: document.getElementById("search"),
  viewAll: document.getElementById("view-all"),
  sheet: document.getElementById("sheet"),
  sheetContent: document.getElementById("sheet-content"),
  sheetClose: document.getElementById("sheet-close"),
  navItems: document.querySelectorAll(".nav-item"),
  goMenu: document.getElementById("go-menu"),
  views: document.querySelectorAll(".view"),
  cartList: document.getElementById("cart-list"),
  cartCount: document.getElementById("cart-count"),
};

const formatPrice = (value, currency = "USD") =>
  new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(value);

const renderHotel = () => {
  const { hotel } = state.data;
  refs.hotelName.textContent = hotel.name;
  refs.hotelTagline.textContent = hotel.tagline;
  refs.hotelHours.textContent = hotel.hours;
};

const renderCategories = () => {
  const chipMarkup = [
    `<button class="chip ${state.category === "all" ? "active" : ""}" data-category="all">All</button>`,
    ...state.data.categories.map(
      (cat) =>
        `<button class="chip ${state.category === cat.id ? "active" : ""}" data-category="${cat.id}">${cat.label}</button>`
    ),
  ].join("");

  refs.categoryChips.innerHTML = chipMarkup;
};

const highlightItems = () => state.data.items.slice(0, 4);

const renderHighlights = () => {
  const highlightMarkup = highlightItems()
    .map(
      (item) => `
      <article class="highlight" data-id="${item.id}">
        <h3>${item.name}</h3>
        <p>${item.description}</p>
        <div class="meta">
          <span>${item.prep}</span>
          <span>${formatPrice(item.price, state.data.hotel.currency)}</span>
        </div>
      </article>
    `
    )
    .join("");

  refs.highlights.innerHTML = highlightMarkup;
};

const matchesFilters = (item) => {
  const matchesCategory =
    state.category === "all" || item.category === state.category;
  const query = state.search.trim().toLowerCase();
  const categoryLabel =
    state.data.categories.find((cat) => cat.id === item.category)?.label || "";
  const categoryAliases =
    state.data.categoryAliases?.[item.category]?.join(" ") || "";
  const tagLabels = item.tags.map((tag) => state.data.labels[tag] || "");
  const keywords = (item.keywords || []).join(" ");
  const matchesSearch =
    query.length === 0 ||
    item.name.toLowerCase().includes(query) ||
    item.description.toLowerCase().includes(query) ||
    categoryLabel.toLowerCase().includes(query) ||
    categoryAliases.toLowerCase().includes(query) ||
    keywords.toLowerCase().includes(query) ||
    tagLabels.some((label) => label.toLowerCase().includes(query));
  return matchesCategory && matchesSearch;
};

const renderMenu = () => {
  const filtered = state.data.items.filter(matchesFilters);
  refs.resultsCount.textContent = `${filtered.length} items`;

  refs.menuList.innerHTML = filtered
    .map((item) => {
      const tags = item.tags
        .map((tag) => `<span class="tag">${state.data.labels[tag]}</span>`)
        .join("");

      return `
        <article class="menu-card" data-id="${item.id}">
          <div>
            <h3>${item.name}</h3>
            <p>${item.description}</p>
          </div>
          <div class="tag-list">${tags}</div>
          <div class="meta-row">
            <span>${item.prep} · ${item.calories} cal</span>
            <span>${formatPrice(item.price, state.data.hotel.currency)}</span>
          </div>
          <button class="fav-toggle ${state.favorites.has(item.id) ? "active" : ""}" type="button" data-fav="${item.id}">
            ${state.favorites.has(item.id) ? "★" : "☆"}
          </button>
        </article>
      `;
    })
    .join("");
};

const renderFavorites = () => {
  const favorites = state.data.items.filter((item) =>
    state.favorites.has(item.id)
  );

  if (favorites.length === 0) {
    refs.favoritesList.innerHTML = `
      <article class="tray-card">
        <h3>No favorites yet</h3>
        <p>Tap ☆ on a dish to add it here.</p>
      </article>
    `;
    return;
  }

  refs.favoritesList.innerHTML = favorites
    .map(
      (item) => `
        <article class="menu-card" data-id="${item.id}">
          <div>
            <h3>${item.name}</h3>
            <p>${item.description}</p>
          </div>
          <div class="meta-row">
            <span>${item.prep} · ${item.calories} cal</span>
            <span>${formatPrice(item.price, state.data.hotel.currency)}</span>
          </div>
          <button class="fav-toggle active" type="button" data-fav="${item.id}">★</button>
        </article>
      `
    )
    .join("");
};

const updateView = (view) => {
  state.activeView = view;
  refs.views.forEach((section) => {
    section.classList.toggle("hidden", !section.classList.contains(`view-${view}`));
  });
  refs.navItems.forEach((item) => {
    item.classList.toggle("active", item.dataset.view === view);
  });
};

const cartSummary = () => {
  const entries = Array.from(state.cart.entries());
  const count = entries.reduce((sum, [, qty]) => sum + qty, 0);
  const total = entries.reduce((sum, [id, qty]) => {
    const item = state.data.items.find((entry) => entry.id === id);
    return item ? sum + item.price * qty : sum;
  }, 0);
  return { entries, count, total };
};

const renderCart = () => {
  const { entries, count, total } = cartSummary();
  refs.cartCount.textContent = `${count} items`;

  if (entries.length === 0) {
    refs.cartList.innerHTML = `
      <article class="tray-card">
        <h3>Tray is empty</h3>
        <p>Add items from the menu to build your tray.</p>
        <button id="go-menu" class="primary-btn" type="button">Browse menu</button>
      </article>
      <button class="primary-btn order-btn" type="button" data-action="place-order">
        Place order
      </button>
    `;
    refs.goMenu = document.getElementById("go-menu");
    refs.goMenu.addEventListener("click", () => updateView("menu"));
    return;
  }

  const itemsMarkup = entries
    .map(([id, qty]) => {
      const item = state.data.items.find((entry) => entry.id === id);
      if (!item) return "";
      return `
        <article class="tray-card cart-item" data-id="${id}">
          <div>
            <h3>${item.name}</h3>
            <p>${item.description}</p>
          </div>
          <div class="cart-row">
            <div class="cart-controls">
              <button type="button" data-action="decrease">-</button>
              <span>${qty}</span>
              <button type="button" data-action="increase">+</button>
            </div>
            <strong>${formatPrice(item.price * qty, state.data.hotel.currency)}</strong>
          </div>
        </article>
      `;
    })
    .join("");

  refs.cartList.innerHTML = `
    ${itemsMarkup}
    <div class="tray-card cart-total">
      <span>Total</span>
      <span>${formatPrice(total, state.data.hotel.currency)}</span>
    </div>
    <button class="primary-btn order-btn" type="button" data-action="place-order">
      Place order
    </button>
  `;
};

const openOrderPopup = () => {
  const { entries, count, total } = cartSummary();
  if (entries.length === 0) return;

  const lines = entries
    .map(([id, qty]) => {
      const item = state.data.items.find((entry) => entry.id === id);
      if (!item) return "";
      return `
        <li>
          <span>${item.name} × ${qty}</span>
          <strong>${formatPrice(item.price * qty, state.data.hotel.currency)}</strong>
        </li>
      `;
    })
    .join("");

  refs.sheetContent.innerHTML = `
    <div class="sheet-content">
      <h3>Order placed</h3>
      <p>Your tray has been sent to the kitchen.</p>
      <ul class="order-list">
        ${lines}
      </ul>
      <div class="cart-total order-total">
        <span>Total</span>
        <span>${formatPrice(total, state.data.hotel.currency)}</span>
      </div>
      <p class="order-note">${count} item${count === 1 ? "" : "s"} will be delivered shortly.</p>
      <button class="primary-btn" type="button" data-action="close-sheet">Done</button>
    </div>
  `;

  refs.sheet.classList.add("show");
  refs.sheet.setAttribute("aria-hidden", "false");
};

const openEmptyOrderPopup = () => {
  refs.sheetContent.innerHTML = `
    <div class="sheet-content">
      <h3>Tray is empty</h3>
      <p>Add items to your tray before placing an order.</p>
      <button class="primary-btn" type="button" data-action="close-sheet">Done</button>
    </div>
  `;

  refs.sheet.classList.add("show");
  refs.sheet.setAttribute("aria-hidden", "false");
};

const openSheet = (item) => {
  const tags = item.tags
    .map((tag) => `<span class="tag">${state.data.labels[tag]}</span>`)
    .join("");

  refs.sheetContent.innerHTML = `
    <div class="sheet-content">
      <h3>${item.name}</h3>
      <p>${item.description}</p>
      <div class="tag-list">${tags}</div>
      <div class="sheet-grid">
        <span><strong>Prep time</strong><span>${item.prep}</span></span>
        <span><strong>Calories</strong><span>${item.calories} cal</span></span>
        <span><strong>Category</strong><span>${
          state.data.categories.find((cat) => cat.id === item.category)?.label ||
          "Signature"
        }</span></span>
        <span><strong>Price</strong><span>${formatPrice(
          item.price,
          state.data.hotel.currency
        )}</span></span>
      </div>
      <button class="primary-btn" type="button" data-action="add-to-cart" data-id="${item.id}">Add to tray</button>
    </div>
  `;

  refs.sheet.classList.add("show");
  refs.sheet.setAttribute("aria-hidden", "false");
};

const closeSheet = () => {
  refs.sheet.classList.remove("show");
  refs.sheet.setAttribute("aria-hidden", "true");
};

const registerEvents = () => {
  refs.categoryChips.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-category]");
    if (!button) return;
    state.category = button.dataset.category;
    renderCategories();
    renderMenu();
  });

  refs.viewAll.addEventListener("click", () => {
    state.category = "all";
    renderCategories();
    renderMenu();
  });

  refs.search.addEventListener("input", (event) => {
    state.search = event.target.value;
    renderMenu();
  });

  refs.highlights.addEventListener("click", (event) => {
    const card = event.target.closest("[data-id]");
    if (!card) return;
    const item = state.data.items.find((entry) => entry.id === card.dataset.id);
    if (item) openSheet(item);
  });

  refs.menuList.addEventListener("click", (event) => {
    const favButton = event.target.closest("[data-fav]");
    if (favButton) {
      const id = favButton.dataset.fav;
      if (state.favorites.has(id)) {
        state.favorites.delete(id);
      } else {
        state.favorites.add(id);
      }
      renderMenu();
      renderFavorites();
      return;
    }
    const card = event.target.closest("[data-id]");
    if (!card) return;
    const item = state.data.items.find((entry) => entry.id === card.dataset.id);
    if (item) openSheet(item);
  });

  refs.favoritesList.addEventListener("click", (event) => {
    const favButton = event.target.closest("[data-fav]");
    if (favButton) {
      const id = favButton.dataset.fav;
      state.favorites.delete(id);
      renderMenu();
      renderFavorites();
      return;
    }
    const card = event.target.closest("[data-id]");
    if (!card) return;
    const item = state.data.items.find((entry) => entry.id === card.dataset.id);
    if (item) openSheet(item);
  });

  refs.navItems.forEach((item) => {
    item.addEventListener("click", () => updateView(item.dataset.view));
  });

  refs.goMenu.addEventListener("click", () => updateView("menu"));

  refs.sheet.addEventListener("click", (event) => {
    if (event.target === refs.sheet) closeSheet();
  });

  refs.sheetClose.addEventListener("click", closeSheet);

  refs.sheetContent.addEventListener("click", (event) => {
    const closeButton = event.target.closest("[data-action=\"close-sheet\"]");
    if (closeButton) {
      closeSheet();
      return;
    }

    const button = event.target.closest("[data-action=\"add-to-cart\"]");
    if (!button) return;
    const id = button.dataset.id;
    state.cart.set(id, (state.cart.get(id) || 0) + 1);
    renderCart();
    closeSheet();
    updateView("cart");
  });

  refs.cartList.addEventListener("click", (event) => {
    const action = event.target.closest("[data-action]")?.dataset.action;
    if (!action) return;

    if (action === "place-order") {
      if (state.cart.size === 0) {
        openEmptyOrderPopup();
        return;
      }
      openOrderPopup();
      state.cart.clear();
      renderCart();
      return;
    }

    const card = event.target.closest("[data-id]");
    if (!card) return;
    const id = card.dataset.id;
    const current = state.cart.get(id) || 0;
    if (action === "increase") state.cart.set(id, current + 1);
    if (action === "decrease") {
      const next = current - 1;
      if (next <= 0) state.cart.delete(id);
      else state.cart.set(id, next);
    }
    renderCart();
  });
};

const init = async () => {
  const res = await fetch(dataPath);
  state.data = await res.json();
  renderHotel();
  renderCategories();
  renderHighlights();
  renderMenu();
  renderFavorites();
  renderCart();
  updateView(state.activeView);
  registerEvents();
};

init();
