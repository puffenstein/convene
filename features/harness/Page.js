import appUrl from "../lib/appUrl.js";
import { By } from "selenium-webdriver";
import Component from "./Component.js";
import PersonNavigationComponent from "./PersonNavigationComponent.js";
class Page {
  /**
   * @param {ThenableWebDriver} driver
   */
  constructor(driver) {
    this.baseUrl = appUrl();
    this.driver = driver;
  }
  /**
   * Factory for building {Component}s
   * @param {string} selector
   * @param {class} componentClass
   * @returns {Component}
   */
  component(selector, componentClass = Component) {
    return new componentClass(this.driver, selector);
  }
  /**
   * @returns {PersonNavigationComponent}
   */
  personNavigation() {
    return this.component(".profile-menu", PersonNavigationComponent);
  }
  /**
   * Goes directly to the page, as defined in the path method.
   * @returns {Promise<this>}
   */
  visit() {
    return this.url()
      .then((url) => this.driver.get(url))
      .then(() => this);
  }
  /**
   * @returns {Promise<string>}
   */
  url() {
    return Promise.resolve(`${this.baseUrl}${this.path()}`);
  }
  /**
   * @param {RegExp} content
   * @returns {Promise<Boolean>}
   */
  hasContent(content) {
    return this.driver
      .findElement(By.tagName("body"))
      .getText()
      .then((body) => body.match(content));
  }
  /**
   * @throws if not defined in child classes
   */
  path() {
    throw "NotImplemented";
  }
}
export default Page;
